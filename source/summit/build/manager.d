/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.build.manager
 *
 * Core build manager + lifecycle management
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.build.manager;

import vibe.d;
import moss.service.context;
import moss.client.metadb;
import summit.models.buildtask;
import summit.models.profile;
import summit.models.project;
import summit.models.repository;
import summit.projects;
import std.algorithm : filter;
import moss.deps.dependency;
import std.range : front, empty;

/**
 * The BuildManager is responsible for ensuring the correct serial
 * update approach for project profiles, and determining anything
 * that might be a valid build candidate.
 */
public final class BuildManager
{
    @disable this();

    /**
     * Construct a new BuildManager instance
     *
     * Params:
     *      context = global service context
     *      projectManager = Instantiated global ProjectManager
     */
    this(ServiceContext context, ProjectManager projectManager) @safe
    {
        this.context = context;
        this.projectManager = projectManager;

        /* All indices must be present on startup. */
        ensureIndicesPresent();
        checkForMissing();
    }

private:

    /**
     * Ensure all indices for each buildable is present
     *
     * This is blocking in a fiber sense, the system continues.
     */
    void ensureIndicesPresent() @safe
    {
        foreach (project; projectManager.projects)
        {
            auto profiles = project.profiles;
            foreach (profile; profiles)
            {
                profile.refresh();
            }
        }
    }

    void checkForMissing() @safe
    {
        /* For all projects */
        foreach (project; projectManager.projects)
        {
            auto projModel = project.model;

            /* For all repositories within each project */
            foreach (repo; project.repositories)
            {
                auto repoModel = repo.model;
                /* And for each build target.. */
                foreach (profile; project.profiles)
                {
                    auto profModel = profile.profile;
                    /* For each buildable item in that repository */
                    foreach (entry; repo.db.list)
                    {
                        foreach (name; entry.providers.filter!(
                                (p) => p.type == ProviderType.PackageName))
                        {
                            auto corresponding = profile.db.byProvider(ProviderType.PackageName,
                                    name.target);
                            if (corresponding.empty)
                            {
                                logDiagnostic("Missing from builds: %s/%s/%s %s-%s",
                                        project.model.slug, repo.model.name,
                                        entry.name, entry.versionIdentifier, entry.sourceRelease);
                                enqueueBuildTask(projModel, repoModel, entry, profModel,
                                        format!"Initial build of %s (%s-%s)"(entry.sourceID,
                                            entry.versionIdentifier, entry.sourceRelease));
                                break;
                            }
                            auto binaryEntry = profile.db.byID(corresponding.front);
                            if (binaryEntry.sourceRelease < entry.sourceRelease)
                            {
                                logDiagnostic("Out of date package %s/%s/%s (recipe: %s-%s, published: %s-%s)",
                                        project.model.slug, repo.model.name, entry.name,
                                        entry.versionIdentifier,
                                        entry.sourceRelease, binaryEntry.versionIdentifier,
                                        binaryEntry.sourceRelease);
                                enqueueBuildTask(projModel, repoModel, entry, profModel,
                                        format!"Update %s from %s-%s to %s-%s"(entry.sourceID,
                                            binaryEntry.versionIdentifier,
                                            binaryEntry.sourceRelease,
                                            entry.versionIdentifier, entry.sourceRelease));
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * Enqueue a build task.
     *
     * Right now we just re-add all tasks, without evaluating existing tasks or
     * performing any depsolving/updates. We're fleshing this iteratively.
     * 
     * Params:
     *      project = Parent project
     *      repository = Parent repository
     *      sourceEntry = Source package being updated
     *      profile = Build profile
     */
    void enqueueBuildTask(Project project, Repository repository,
            MetaEntry sourceEntry, Profile profile, string description) @safe
    {
        BuildTask model;
        model.id = 0;
        model.status = BuildTaskStatus.New;
        model.slug = format!"~/%s/%s/%s"(project.slug, repository.name, sourceEntry.name);
        model.profileID = profile.id;
        model.description = description;
        model.repoID = repository.id;
        model.commitRef = repository.commitRef;
        model.sourcePath = sourceEntry.sourcePath;
        model.buildID = format!"%s / %s / %s-%s-%s-%s"(project.slug, repository.name, sourceEntry.sourceID,
                sourceEntry.versionIdentifier, sourceEntry.sourceRelease, profile.arch);
        model.tsStarted = Clock.currTime(UTC()).toUnixTime();
        model.tsUpdated = model.tsStarted;

        immutable err = context.appDB.update((scope tx) => model.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        logInfo(format!"New buildTask: %s"(model));
    }

    ServiceContext context;
    ProjectManager projectManager;
}

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

import moss.client.metadb;
import moss.deps.dependency;
import moss.deps.digraph;
import moss.deps.registry;
import moss.service.context;
import std.algorithm : canFind, each, filter, map;
import std.range : chain, empty, front;
import summit.build.sourceplugin;
import summit.models.buildtask;
import summit.models.profile;
import summit.models.project;
import summit.models.repository;
import summit.projects;
import vibe.d;

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
        loadTasks();
        checkForMissing();
        recomputeQueue();
        logInfo(format!"Current build queue ordering: %s"(orderedQueue));
    }

    /** 
     * Returns: All enqueued jobs with numDeps == 0 and in build order.
     */
    auto availableJobs() @safe
    {
        return orderedQueue.filter!((j) => j.numDeps == 0);
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
        BuildTask existingJob;
        model.buildID = format!"%s / %s / %s-%s-%s_%s-%s"(project.slug, repository.name, sourceEntry.sourceID,
                sourceEntry.versionIdentifier, sourceEntry.sourceRelease,
                sourceEntry.buildRelease, profile.arch);

        /* Don't queue the same job again */
        immutable lookupErr = context.appDB.view((in tx) => existingJob.load!"buildID"(tx,
                model.buildID));
        if (lookupErr.isNull)
        {
            return;
        }

        model.id = 0;
        model.status = BuildTaskStatus.New;
        model.slug = format!"~/%s/%s/%s"(project.slug, repository.name, sourceEntry.name);
        model.projectID = project.id;
        model.profileID = profile.id;
        model.description = description;
        model.repoID = repository.id;
        model.pkgID = sourceEntry.pkgID;
        model.commitRef = repository.commitRef;
        model.sourcePath = sourceEntry.sourcePath;
        model.tsStarted = Clock.currTime(UTC()).toUnixTime();
        model.tsUpdated = model.tsStarted;

        immutable err = context.appDB.update((scope tx) => model.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        logInfo(format!"New buildTask: %s"(model));
        enlivenTask(model);
    }

    /**
     * Load all tasks from the DB that need work on startup
     * This may take some time when processing all tasks.
     */
    void loadTasks() @safe
    {
        /* empty the mapping */
        queue = null;

        immutable err = context.appDB.view((scope tx) @safe {
            auto workable = tx.list!BuildTask
                .filter!((t) => t.status != BuildTaskStatus.Failed
                    && t.status != BuildTaskStatus.Completed);
            workable.each!((w) => enlivenTask(w));
            return NoDatabaseError;
        });
    }

    /**
     * Bring the DB task into the live queue for processing
     *
     * Params:
     *      task = Stale task for renewal
     */
    void enlivenTask(BuildTask task) @safe
    {
        logDiagnostic(format!"enliven: %s"(task.buildID));
        queue[task.id] = task;
    }

    /**
     * From the current job pool, determine resolveable
     * dependencies between all of the jobs and sort by
     * that ordering.
     *
     * Note that upon execution we understand our previous jobs
     * to have run to completion and the binary indices to be
     * up to date, allowing an in-depth deps analysis to happen
     * to ensure the job is possible.
     */
    void recomputeQueue() @safe
    {
        auto dag = new DirectedAcyclicalGraph!BuildTaskID;
        JobMapper[BuildTaskID] mappedEntries;
        queue.values.each!((t) => mappedEntries[t.id] = lookupTask(t));

        /* Insert all vertices first */
        mappedEntries.values.each!((m) => dag.addVertex(m.task.id));
        foreach (_, ref currentItem; mappedEntries)
        {
            /* Find commonality: All items whose publication index matches our input "remotes" */
            auto commonQueue = mappedEntries.values
                .filter!((q) => q.task.id != currentItem.task.id)
                .filter!((q) => currentItem.remotes.canFind!((a) => a == q.indexURI));

            /* For all of our deps, find a provider in the commonQueue to link these foreign items */
            foreach (dep; currentItem.entry.buildDependencies.chain(currentItem.entry.dependencies))
            {
                auto metDeps = commonQueue.filter!((d) => d.entry.providers.canFind!(
                        (p) => p.target == dep.target && dep.type == p.type));
                metDeps.each!((e) => dag.addEdge(currentItem.task.id, e.task.id));
            }
            currentItem.numDeps = dag.countEdges(currentItem.task.id);
        }

        orderedQueue = null;
        dag.breakCycles();
        dag.topologicalSort((d) { orderedQueue ~= mappedEntries[d]; });
    }

    /**
     * Grab the proper SOURCE entry for the task from its DB
     */
    JobMapper lookupTask(BuildTask task) @safe
    {
        Project project;
        Profile profile;
        Repository repo;

        /* Grab all models */
        immutable err = context.appDB.view((in tx) @safe {
            auto e = project.load(tx, task.projectID);
            if (!e.isNull)
            {
                return e;
            }
            auto e2 = profile.load(tx, task.profileID);
            if (!e2.isNull)
            {
                return e2;
            }
            return repo.load(tx, task.repoID);
        });

        if (!err.isNull)
        {
            logDiagnostic(format!"Unable to load task %s: %s"(task.buildID, err.message));
            return JobMapper.init;
        }
        /* TODO: Install the remotes PROPERLY */
        auto mProject = projectManager.bySlug(project.slug);
        auto mRepo = mProject.bySlug(repo.name);
        auto entry = mRepo.db.byID(task.pkgID);
        return JobMapper(entry, task, [profile.volatileIndexURI], profile.volatileIndexURI);
    }

    ServiceContext context;
    ProjectManager projectManager;
    BuildTask[BuildTaskID] queue;
    JobMapper[] orderedQueue;
}

/**
 * Encapsulation of a job environment - used solely for calculating the build order.
 * Much of the information is thrown away after calculation
 */
private struct JobMapper
{
    /**
     * Source entry for this job
     */
    MetaEntry entry;

    /**
     * Real build task
     */
    BuildTask task;

    /**
     * All configured remotes
     */
    string[] remotes;

    /**
     * The publication index URI
     */
    string indexURI;

    /**
     * Number of dependencies required
     */
    ulong numDeps;
}

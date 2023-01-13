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
            /* For all repositories within each project */
            foreach (repo; project.repositories)
            {
                /* And for each build target.. */
                foreach (profile; project.profiles)
                {
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
                                logInfo("Missing from builds: %s/%s/%s %s-%s",
                                        project.model.slug, repo.model.name, entry.name,
                                        entry.versionIdentifier, entry.sourceRelease);
                                break;
                            }
                            auto binaryEntry = profile.db.byID(corresponding.front);
                            if (binaryEntry.sourceRelease < entry.sourceRelease)
                            {
                                logInfo("Out of date package %s/%s/%s (recipe: %s-%s, published: %s-%s)",
                                        project.model.slug, repo.model.name, entry.name,
                                        entry.versionIdentifier,
                                        entry.sourceRelease, binaryEntry.versionIdentifier,
                                        binaryEntry.sourceRelease);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    ServiceContext context;
    ProjectManager projectManager;
}

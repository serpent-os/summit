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
    }

private:

    ServiceContext context;
    ProjectManager projectManager;
}

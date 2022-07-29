/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.projects;
 *
 * The projects web UI
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.projects;

import vibe.d;

/**
 * Web interface providing the UI experience
 */
@path("projects") public final class ProjectsWeb
{
    this() @safe
    {

    }

    /**
     * Render the home page
     */
    void index()
    {
        render!("projects/index.dt");
    }
}

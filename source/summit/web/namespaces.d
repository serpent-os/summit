/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.namespaces;
 *
 * The projects web UI
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.namespaces;

import vibe.d;
import std.typecons : Nullable;

/**
 * Web interface providing the UI experience
 */
@path("~") public final class NamespacesWeb
{

    /**
     * Render the landing page
     */
    @method(HTTPMethod.GET)
    void index() @safe
    {
        render!("namespaces/index.dt");
    }

    /**
     * View a single namespace
     *
     * Params:
     *      _path = The path portion to render
     */
    @path("/:path") @method(HTTPMethod.GET)
    void view(string _path) @safe
    {
        render!("namespaces/index.dt", path);
    }
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.builders;
 *
 * The builders web UI
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.builders;

import vibe.d;
import std.typecons : Nullable;

/**
 * Web interface providing the UI experience
 */
@path("builders") public final class BuildersWeb
{

    /**
     * Render the landing page
     */
    @method(HTTPMethod.GET)
    void index() @safe
    {
        render!("builders/index.dt");
    }
}

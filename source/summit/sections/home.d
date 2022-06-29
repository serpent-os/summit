/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.home
 *
 * Home page rendering
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.sections.home;

import vibe.vibe;

/**
 * Implements the / path
 */
public final class HomeSection
{
    /**
     * Render the index page
     */
    @method(HTTPMethod.GET) @path("/") void index() @safe
    {
        render!"home.dt";
    }
}

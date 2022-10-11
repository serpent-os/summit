/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web
 *
 * Root web application (nested)
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web;

import vibe.d;

/**
 * Root entry into our web service
 */
@path("/")
public final class SummitWeb
{
    /**
     * Join SummitWeb into the router
     *
     * Params:
     *      router = Base root for the application
     */
    @noRoute void configure(URLRouter router) @safe
    {
        registerWebInterface(router, this);
    }

    /**
     * Return the "home" page
     */
    void index() @safe
    {
        render!"index.dt";
    }
}

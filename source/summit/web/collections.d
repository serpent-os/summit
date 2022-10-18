/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.collections
 *
 * Collections Web API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.collections;

import vibe.d;

/**
 * Root entry into our web service
 */
@path("/~")
public final class CollectionsWeb
{
    /**
     * Join CollectionsWeb into the router
     *
     * Params:
     *      router = Web root for the application
     */
    @noRoute void configure(URLRouter router) @safe
    {
        registerWebInterface(router, this);
    }

    /**
     * Collections index
     */
    void index() @safe
    {
        render!"collections/index.dt";
    }

    /**
     * View an individual collection
     *
     * Params:
     *      _slug = Specific slug ID (i.e. collection short name)
     */
    @path("/:slug") @method(HTTPMethod.GET)
    void view(string _slug)
    {
        render!"collections/view.dt";
    }
}

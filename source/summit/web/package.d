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
import summit.web.accounts;
import summit.web.collections;

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
        auto root = registerWebInterface(router, this);
        auto act = new AccountsWeb();
        act.configure(root);
        auto col = new CollectionsWeb();
        col.configure(root);
    }

    /**
     * Return the "home" page
     */
    void index() @safe
    {
        render!"index.dt";
    }
}

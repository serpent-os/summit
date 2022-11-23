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
import summit.context;

/**
 * Root entry into our web service
 */
@path("/")
public final class SummitWeb
{
    @disable this();

    /**
     * Construct a new SummitWeb instance
     *
     * Params:
     *      context = global context
     *      router = nested routes
     */
    this(SummitContext context, URLRouter router) @safe
    {
        auto root = router.registerWebInterface(this);
        root.registerWebInterface(cast(AccountsWeb) new SummitAccountsWeb(context));
        root.registerWebInterface(new CollectionsWeb(context));
    }

    /**
     * Return the "home" page
     */
    void index() @safe
    {
        render!"index.dt";
    }

    /**
     * Render the /builders page
     */
    @path("builders") @method(HTTPMethod.GET)
    void buildersPage() @safe
    {
        render!"builders/index.dt";
    }
}

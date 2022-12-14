/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web
 *
 * Root web application (nested)
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.web;

import moss.service.context;
import summit.collections;
import summit.web.accounts;
import summit.web.collections;
import vibe.d;

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
     *      collectionManager = collection management
     *      router = nested routes
     */
    this(ServiceContext context, CollectionManager collectionManager, URLRouter router) @safe
    {
        auto root = router.registerWebInterface(this);
        root.registerWebInterface(cast(AccountsWeb) new SummitAccountsWeb(context));
        root.registerWebInterface(new CollectionsWeb(context, collectionManager));
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

    /**
     * Render the /endpoints page
     */
    @path("endpoints") @method(HTTPMethod.GET)
    void endpointsPage() @safe
    {
        render!"endpoints/index.dt";
    }
}

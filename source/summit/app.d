/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.app
 *
 * Core application lifecycle
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.app;

import moss.core.errors;
import moss.service.accounts;
import moss.service.models;
import std.path : buildPath;
import summit.api;
import summit.collections;
import summit.context;
import summit.models;
import summit.web;
import vibe.d;

/**
 * SummitApplication provides the main dashboard application
 * seen by users after the setup app is complete.
 */
public final class SummitApplication
{
    @disable this();

    /**
     * Construct new App 
     *
     * Params:
     *      context = application context
     */
    this(SummitContext context) @safe
    {
        this.context = context;
        this.collectionManager = new CollectionManager(context);
        _router = new URLRouter();

        web = new SummitWeb();
        web.configure(context.appDB, context.accountManager, context.tokenManager, router);

        service = new RESTService(context, router);
    }

    /**
     * Returns: mapped router
     */
    pragma(inline, true) pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

    /**
     * Close down the app/instance
     */
    void close() @safe
    {
        collectionManager.close();
    }

private:

    CollectionManager collectionManager;
    SummitContext context;
    RESTService service;
    URLRouter _router;
    SummitWeb web;
}

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

import vibe.d;
import moss.client.metadb;
import moss.core.errors;
import moss.service.accounts;
import moss.service.models;
import std.path : buildPath;
import summit.web;
import summit.api;
import summit.context;
import summit.models;
import summit.workers;

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
        metaDB = new MetaDB(context.dbPath.buildPath("metaDB"), true);
        metaDB.connect.tryMatch!((Success _) {});
        _router = new URLRouter();

        web = new SummitWeb();
        web.configure(context.appDB, metaDB, context.accountManager, context.tokenManager, router);

        /* Get worker system up and running */
        worker = new WorkerSystem(context.rootDirectory, context.appDB, metaDB);
        worker.start();

        service = new RESTService(context.rootDirectory);
        service.configure(worker, context.accountManager, context.tokenManager,
                metaDB, context.appDB, router);
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
        worker.close();
        metaDB.close();
    }

private:

    SummitContext context;
    RESTService service;
    URLRouter _router;
    SummitWeb web;
    MetaDB metaDB;
    WorkerSystem worker;
}

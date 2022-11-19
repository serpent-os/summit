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
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.models;
import summit.workers;
import moss.service.tokens;
import moss.service.tokens.manager;
import std.base64 : Base64URLNoPadding;

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
     *      rootDir = Root directory
     */
    this(string rootDir) @safe
    {
        immutable statePath = rootDir.buildPath("state");
        immutable dbPath = statePath.buildPath("db");

        tokenManager = new TokenManager(statePath);
        logInfo(format!"Instance pubkey: %s"(tokenManager.publicKey));

        /* *has* to work */
        Database.open(format!"lmdb://%s"(dbPath.buildPath("app")),
                DatabaseFlags.CreateIfNotExists).tryMatch!((Database db) {
            appDB = db;
        });

        metaDB = new MetaDB(dbPath.buildPath("metaDB"), true);
        metaDB.connect.tryMatch!((Success _) {});

        immutable dbErr = appDB.update((scope tx) => tx.createModel!(PackageCollection,
                Repository, AvalancheEndpoint));
        enforceHTTP(dbErr.isNull, HTTPStatus.internalServerError, dbErr.message);

        accountManager = new AccountManager(dbPath.buildPath("accounts"));

        _router = new URLRouter();

        web = new SummitWeb();
        web.configure(appDB, metaDB, accountManager, tokenManager, router);

        /* Get worker system up and running */
        worker = new WorkerSystem(rootDir, appDB, metaDB);
        worker.start();

        service = new RESTService(rootDir);
        service.configure(worker, accountManager, tokenManager, metaDB, appDB, router);
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
        appDB.close();
        accountManager.close();
        worker.close();
        metaDB.close();
    }

private:

    RESTService service;
    AccountManager accountManager;
    URLRouter _router;
    SummitWeb web;
    Database appDB;
    MetaDB metaDB;
    WorkerSystem worker;
    TokenManager tokenManager;
}

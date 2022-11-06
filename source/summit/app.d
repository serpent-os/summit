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
import moss.service.sessionstore;
import moss.service.models;
import std.file : mkdirRecurse;
import std.path : buildPath;
import summit.web;
import summit.api;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.models;
import summit.workers;

/**
 * SummitApplication maintains the core lifecycle of Summit
 * and the event processing
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
        logInfo(format!"SummitApplication running from %s"(rootDir));

        immutable statePath = rootDir.buildPath("state");
        immutable dbPath = statePath.buildPath("db");
        dbPath.mkdirRecurse();

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

        router = new URLRouter();

        /* Set up the server */
        serverSettings = new HTTPServerSettings();
        serverSettings.bindAddresses = ["localhost",];
        serverSettings.disableDistHost = true;
        serverSettings.useCompressionIfPossible = true;
        serverSettings.port = 8081;
        serverSettings.sessionOptions = SessionOption.secure | SessionOption.httpOnly;
        serverSettings.serverString = "summit/0.0.1";
        serverSettings.sessionIdCookie = "summit.session_id";

        /* Session persistence */
        sessionStore = new DBSessionStore(dbPath.buildPath("session"));
        serverSettings.sessionStore = sessionStore;

        /* File settings for /static/ serving */
        fileSettings = new HTTPFileServerSettings();
        fileSettings.serverPathPrefix = "/static";
        //fileSettings.maxAge = 30.days;
        fileSettings.options = HTTPFileServerOption.failIfNotFound;
        router.get("/static/*", serveStaticFiles(rootDir.buildPath("static/"), fileSettings));

        web = new SummitWeb();
        web.configure(appDB, metaDB, accountManager, router);

        /* Get worker system up and running */
        worker = new WorkerSystem(rootDir, appDB, metaDB);
        worker.start();

        service = new RESTService(rootDir);
        service.configure(worker, metaDB, appDB, router);

        /* Lets go listen */
        listener = listenHTTP(serverSettings, router);
    }

    /**
     * Close down the app/instance
     */
    void close() @safe
    {
        listener.stopListening();
        appDB.close();
        accountManager.close();
        worker.close();
        metaDB.close();
    }

private:

    RESTService service;
    AccountManager accountManager;
    HTTPListener listener;
    HTTPServerSettings serverSettings;
    HTTPFileServerSettings fileSettings;
    URLRouter router;
    DBSessionStore sessionStore;
    SummitWeb web;
    Database appDB;
    MetaDB metaDB;
    WorkerSystem worker;
}

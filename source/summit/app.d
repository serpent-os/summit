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
import std.file : mkdirRecurse, exists;
import std.path : buildPath;
import summit.web;
import summit.api;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.models;
import summit.workers;
import moss.service.tokens;
import std.base64 : Base64URLNoPadding;

private enum TokenPaths : string
{
    Seed = ".seed",
    PublicKey = ".pubkey",
    PrivateKey = ".privkey",
};

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

        initTokens(statePath);

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

    /**
     * Initialise token management
     *
     * Params:
     *      statePath = State storage path
     */
    void initTokens(string statePath) @safe
    {
        immutable seedPath = statePath.buildPath(TokenPaths.Seed);
        immutable privatePath = statePath.buildPath(TokenPaths.PrivateKey);
        immutable publicPath = statePath.buildPath(TokenPaths.PublicKey);

        if (!seedPath.exists)
        {
            seed = createSeed();
            logWarn(format!"Writing new seed to %s"(seedPath));
            writeFile(NativePath(seedPath), seed);
        }
        else
        {
            auto tempSeed = readFile(seedPath);
            enforce(tempSeed.length == seed.length, "Invalid TokenSeed!");
            seed = tempSeed[0 .. tempSeed.length];
            logInfo("Loaded instance seed");
        }

        /* Regen required? */
        if (!privatePath.exists || !publicPath.exists)
        {
            logWarn("Generating new signing pair");
            pair = TokenSigningPair.create(seed);
            logDiagnostic(format!"Writing pubkey to %s"(publicPath));
            writeFile(NativePath(privatePath), pair.secretKey);
            logDiagnostic(format!"Writing privkey to %s"(privatePath));
            writeFile(NativePath(publicPath), pair.publicKey);
        }
        else
        {
            logInfo("Loading signing pair from disk");

            /* Load disk pair */
            auto tempPublic = readFile(publicPath);
            auto tempPrivate = readFile(privatePath);

            enforce(tempPublic.length == pair.publicKey.length, "Invalid public key");
            enforce(tempPrivate.length == pair.secretKey.length, "Invalid private key");

            pair.publicKey = tempPublic[0 .. pair.publicKey.length];
            pair.secretKey = tempPrivate[0 .. pair.secretKey.length];
        }

        pubkeyRepresentation = Base64URLNoPadding.encode(pair.publicKey);
        logInfo(format!"Utilising public key '%s'"(pubkeyRepresentation));
    }

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
    TokenSeed seed;
    TokenSigningPair pair;
    string pubkeyRepresentation;
}

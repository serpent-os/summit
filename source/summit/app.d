/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.app
 *
 * Main application instance housing the Dashboard app
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.app;

import vibe.d;
import vibe.http.fileserver;
import summit.sessionstore;
import moss.db.keyvalue;
import moss.db.keyvalue.interfaces;
import moss.db.keyvalue.orm;

import std.file : exists, mkdir;

import summit.models;
import summit.web;

/**
 * Main entry point from the server side, storing our
 * databases and interfaces.
 */
public final class SummitApp
{
    /**
     * Construct a new SummitApp
     */
    this() @safe
    {
        if (!"database".exists)
        {
            mkdir("database");
        }
        settings = new HTTPServerSettings();
        settings.disableDistHost = true;
        settings.useCompressionIfPossible = true;
        settings.bindAddresses = ["127.0.0.1"];
        settings.port = 8081;
        settings.sessionIdCookie = "summit/session_id";
        settings.sessionOptions = SessionOption.httpOnly | SessionOption.secure;
        settings.sessionStore = new DBSessionStore("lmdb://database/session");

        /* Get our app db open */
        appDB = Database.open("lmdb://database/app",
                DatabaseFlags.CreateIfNotExists).tryMatch!((Database db) => db);

        /* Ensure all models exist */
        auto err = appDB.update((scope tx) @safe {
            return tx.createModel!(User, Group, Token);
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Bring up our core routes */
        router = new URLRouter();
        router.registerWebInterface(new Web());

        /* Enable file sharing from static/ */
        fileSettings = new HTTPFileServerSettings();
        fileSettings.serverPathPrefix = "/static";
        router.get("/static/*", serveStaticFiles("static", fileSettings));
    }

    /**
     * Start the app properly
     */
    void start() @safe
    {
        listener = listenHTTP(settings, router);
    }

    /**
     * Correctly stop the application
     */
    void stop() @safe
    {
        listener.stopListening();

    }

private:
    URLRouter router;
    HTTPServerSettings settings;
    HTTPListener listener;
    HTTPFileServerSettings fileSettings;
    Database appDB;
}

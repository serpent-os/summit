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
        bool initDefaults;

        if (!"database".exists)
        {
            mkdir("database");
            initDefaults = true;
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
            return tx.createModel!(User, Group, Token, Project);
        });

        if (initDefaults)
        {
            createDefaults();
        }
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Bring up our core routes */
        router = new URLRouter();
        auto web = new Web();
        auto webRoot = router.registerWebInterface(web);
        web.configure(webRoot);

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

    /**
     * TODO: Use fixtures!
     */
    void createDefaults() @safe
    {
        Group[] groups = [Group(0, "Core Team")];
        Project[] projects = [
            Project(0, "Serpent OS", "Official Serpent OS Development", "## Serpent OS

This is the *official* [Serpent OS](https://serpentos.com) build project, housing
all of our packages and updates.
")
        ];

        auto err = appDB.update((scope tx) @safe {
            foreach (group; groups)
            {
                auto err = group.save(tx);
                if (!err.isNull)
                {
                    return err;
                }
            }
            foreach (proj; projects)
            {
                auto err = proj.save(tx);
                if (!err.isNull)
                {
                    return err;
                }
            }
            return NoDatabaseError;
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    URLRouter router;
    HTTPServerSettings settings;
    HTTPListener listener;
    HTTPFileServerSettings fileSettings;
    Database appDB;
}

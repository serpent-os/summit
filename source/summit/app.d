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

import summit.accounts;
import summit.models;
import summit.web;
import summit.rest;

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
        settings.serverString = "summit/0.0.1";

        /* Open the accounts DB */
        accountManager = new AccountManager("lmdb://database/accounts");

        /* Get our app db open */
        appDB = Database.open("lmdb://database/app",
                DatabaseFlags.CreateIfNotExists).tryMatch!((Database db) => db);

        /* Ensure all models exist */
        auto err = appDB.update((scope tx) @safe {
            return tx.createModel!(Token, Project, Namespace, Builder, BuildJob, Repository);
        });

        if (initDefaults)
        {
            createDefaults();
        }
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Bring up our core routes */
        router = new URLRouter();
        auto web = new Web();
        web.configure(router, appDB, accountManager);

        auto api = new BaseAPI();
        api.configure(router, appDB, accountManager);

        /* Enable file sharing from static/ */
        fileSettings = new HTTPFileServerSettings();
        fileSettings.serverPathPrefix = "/static";
        router.get("/static/*", serveStaticFiles("static", fileSettings));

        router.rebuild();

        debug
        {
            import std.stdio : writeln;
        }
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
        string desc = import("ns.md");
        Namespace coreNamespace = Namespace(0, "serpent-os", "Serpent OS",
                "Official development", desc);
        Project[] projects = [
            Project(0, "base", "Base", 0, "Core recipes (non booting)"),
            Project(0, "freedesktop", "Freedesktop", 0,
                    "Freedesktop (XDG) compatibility + software"),
            Project(0, "gnome", "GNOME", 0, "GNOME software + libraries"),
            Project(0, "hardware", "Hardware", 0, "Hardware enabling"),
            Project(0, "kernel", "Kernel", 0, "Upstream kernel packaging for Serpent OS"),
            Project(0, "plasma", "Plasma / KDE", 0, "Plasma desktop + software"),
            Project(0, "toolchain", "Toolchain", 0, "Core Serpent OS toolchains"),
        ];

        auto err = appDB.update((scope tx) @safe {
            /* Create ID for namespace */
            {
                auto err = coreNamespace.save(tx);
                if (!err.isNull)
                {
                    return err;
                }
            }
            foreach (proj; projects)
            {
                proj.namespace = coreNamespace.id;
                auto err = proj.save(tx);
                if (!err.isNull)
                {
                    return err;
                }
                coreNamespace.projects ~= proj.id;
            }
            return coreNamespace.save(tx);
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    URLRouter router;
    HTTPServerSettings settings;
    HTTPListener listener;
    HTTPFileServerSettings fileSettings;
    Database appDB;
    AccountManager accountManager;
}

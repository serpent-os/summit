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

        /* Get our app db open */
        appDB = Database.open("lmdb://database/app",
                DatabaseFlags.CreateIfNotExists).tryMatch!((Database db) => db);

        /* Ensure all models exist */
        auto err = appDB.update((scope tx) @safe {
            return tx.createModel!(User, Group, Token, Project, Namespace);
        });

        if (initDefaults)
        {
            createDefaults();
        }
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Bring up our core routes */
        router = new URLRouter();
        auto web = new Web();
        web.configure(router);

        auto api = new BaseAPI();
        api.configure(router, appDB);

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
        Group[] groups = [Group(0, "Core Team")];
        Namespace coreNamespace = Namespace(0, "serpent-os", "Official development", "
Official namespace for all [Serpent OS](https://serpentos.com) development. Each major
unit of development is organised into projects matching our [GitLab instance](https://gitlab.com/serpent-os/).


![serpent](/static/black_withtext_4x.png)
");
        Project[] projects = [
            Project(0, "base", 0, "Core recipes (non booting)"),
            Project(0, "freedesktop", 0, "Freedesktop (XDG) compatibility + software"),
            Project(0, "gnome", 0, "GNOME software + libraries"),
            Project(0, "hardware", 0, "Hardware enabling"),
            Project(0, "kernel", 0, "Upstream kernel packaging for Serpent OS"),
            Project(0, "plasma", 0, "Plasma desktop + software"),
            Project(0, "toolchain", 0, "Core Serpent OS tooclhains"),
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
}

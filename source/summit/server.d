/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.server
 *
 * Primary server process. Enables switching between setup and primary
 * application, only enables the session store by itself
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.server;

import vibe.d;
import moss.service.sessionstore;
import std.path : buildPath;
import std.string : format;
import std.file : mkdirRecurse;
import summit.app;
import summit.setup;
import vibe.core.channel;

private enum ApplicationMode
{
    Standard,
    Setup
}

/**
 * SummitApplication maintains the core lifecycle of Summit
 * and the event processing
 */
public final class SummitServer
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
        logInfo(format!"SummitServer running from %s"(rootDir));
        this.rootDir = rootDir;

        immutable statePath = rootDir.buildPath("state");
        immutable dbPath = statePath.buildPath("db");
        dbPath.mkdirRecurse();

        /* Set up the server */
        serverSettings = new HTTPServerSettings();
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
        fileHandler = serveStaticFiles(rootDir.buildPath("static/"), fileSettings);

        /* Lets go listen */
        listener = listenHTTP(serverSettings, &applicationRouting);

        initSetupApp();
    }

    /**
     * Close down the app/instance
     */
    void close() @safe
    {
        listener.stopListening();
    }

    /**
     * Handle all application level routing
     *
     * Params:
     *      request = Incoming request from a client
     *      response = Outgoing response to the client
     */
    void applicationRouting(scope HTTPServerRequest request, scope HTTPServerResponse response) @safe
    {
        final switch (appMode)
        {
        case ApplicationMode.Standard:
            webApp.router.handleRequest(request, response);
            break;
        case ApplicationMode.Setup:
            setupApp.router.handleRequest(request, response);
            break;
        }
    }

private:

    /**
     * Sanely initialise web application
     */
    void initWebApp() @safe
    {
        appMode = ApplicationMode.Standard;
        webApp = new SummitApplication(rootDir);
        webApp.router.get("/static/*", fileHandler);
    }

    /**
     * Sanely initialise setup application
     */
    void initSetupApp() @safe
    {
        /* Notifier channel */
        Channel!(bool, 1) doneWork = createChannel!(bool, 1);
        runTask({
            bool done;
            doneWork.tryConsumeOne(done);

            /* Switch from setup to running application */
            setupApp = null;
            initWebApp();
        });

        appMode = ApplicationMode.Setup;
        setupApp = new SetupApplication(doneWork);
        setupApp.router.get("/static/*", fileHandler);
    }

    string rootDir;
    ApplicationMode appMode = ApplicationMode.Setup;
    SummitApplication webApp;
    SetupApplication setupApp;

    HTTPListener listener;
    HTTPServerSettings serverSettings;
    HTTPFileServerSettings fileSettings;
    DBSessionStore sessionStore;
    HTTPServerRequestDelegate fileHandler;
}

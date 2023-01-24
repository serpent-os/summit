/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * main
 *
 * Main entry for Summit
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module main;

import libsodium : sodium_init;
import moss.service.context;
import moss.service.models;
import std.conv : to;
import std.path : absolutePath, asNormalizedPath;
import summit.models;
import moss.service.server;
import vibe.d;
import summit.app;
import summit.setup;

/**
 * Main entry for summit
 *
 * Params:
 *      args = Runtime arguments
 * Returns: 0 on success
 */
int main(string[] args) @safe
{
    logInfo("Initialising libsodium");
    immutable sret = () @trusted { return sodium_init(); }();
    enforce(sret == 0, "Failed to initialise libsodium");

    immutable rootDir = ".".absolutePath.asNormalizedPath.to!string;
    setLogLevel(LogLevel.trace);

    auto server = new Server!(SetupApplication, SummitApplication)(rootDir);
    scope (exit)
    {
        server.close();
    }
    server.serverSettings.port = 8081;
    server.serverSettings.serverString = "summit/0.0.1";
    server.serverSettings.sessionIdCookie = "summit.session_id";

    /* Configure the model */
    immutable dbErr = server.context.appDB.update((scope tx) => tx.createModel!(Project, Profile,
            Remote, Repository, BuildTask, AvalancheEndpoint, VesselEndpoint, Settings));
    enforceHTTP(dbErr.isNull, HTTPStatus.internalServerError, dbErr.message);

    const settings = getSettings(server.context.appDB).tryMatch!((Settings s) => s);
    server.mode = settings.setupComplete ? ApplicationMode.Main : ApplicationMode.Setup;
    server.start();

    return runApplication();
}

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
import moss.service.server;
import std.conv : to;
import std.getopt;
import std.path : absolutePath, asNormalizedPath;
import summit.app;
import summit.models;
import summit.setup;
import vibe.d;

/**
 * Main entry for summit
 *
 * Params:
 *      args = Runtime arguments
 * Returns: 0 on success
 */
int main(string[] args) @safe
{
    ushort portNumber = 8081;
    /* It's safer to set this to localhost and allow the user to override (not append!) */
    static string[] defaultAddress = ["localhost"];
    string[] cmdLineAddresses;

    auto opts = () @trusted {
        return getopt(args, config.bundling, "p|port", "Specific port to serve on",
                &portNumber, "a|address", "Host address to bind to", &cmdLineAddresses);
    }();

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("avalanche", opts.options);
        return 1;
    }

    logInfo("Initialising libsodium");
    immutable sret = () @trusted { return sodium_init(); }();
    enforce(sret == 0, "Failed to initialise libsodium");

    immutable rootDir = ".".absolutePath.asNormalizedPath.to!string;
    auto server = new Server!(SetupApplication, SummitApplication)(rootDir);
    scope (exit)
    {
        server.close();
    }
    server.serverSettings.bindAddresses = cmdLineAddresses.empty ? defaultAddress : cmdLineAddresses;
    server.serverSettings.port = portNumber;
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

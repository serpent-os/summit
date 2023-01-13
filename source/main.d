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
import summit.server;
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
    logInfo("Initialising libsodium");
    immutable sret = () @trusted { return sodium_init(); }();
    enforce(sret == 0, "Failed to initialise libsodium");

    immutable rootDir = ".".absolutePath.asNormalizedPath.to!string;
    setLogLevel(LogLevel.trace);

    auto context = new ServiceContext(rootDir);

    /* Configure the model */
    immutable dbErr = context.appDB.update((scope tx) => tx.createModel!(Project, Profile,
            Remote, Repository, BuildTask, AvalancheEndpoint, VesselEndpoint, Settings));
    enforceHTTP(dbErr.isNull, HTTPStatus.internalServerError, dbErr.message);

    auto server = new SummitServer(context);
    scope (exit)
    {
        server.close();
    }
    return runApplication();
}

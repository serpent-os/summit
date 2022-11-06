/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * main
 *
 * Main entry for Summit
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module main;

import vibe.d;
import summit;
import std.path : absolutePath, asNormalizedPath;
import std.conv : to;
import libsodium : sodium_init;

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

    auto app = new SummitApplication(rootDir);
    scope (exit)
    {
        app.close();
    }
    return runApplication();
}

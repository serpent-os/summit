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

/**
 * Main entry for summit
 *
 * Params:
 *      args = Runtime arguments
 * Returns: 0 on success
 */
int main(string[] args) @safe
{
    immutable rootDir = ".".absolutePath.asNormalizedPath.to!string;

    auto app = new SummitApplication(rootDir);
    scope (exit)
    {
        app.close();
    }
    return runApplication();
}

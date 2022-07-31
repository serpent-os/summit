/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * main
 *
 * Main entry point into Summit Dashboard
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module main;

import vibe.d;
import libsodium;
import summit.app;

/**
 * Gets our dashboard web + RPC up and running
 *
 * Throws: Exception if libsodium cannot be initialised
 * Params:
 *      args = CLI arguments
 * Returns: 0 if everything went to plan
 */
int main(string[] args)
{
    /**
     * Get sodium setup
     */
    logInfo("Initialising libsodium");
    const ret = sodium_init();
    enforce(ret == 0, "Failed to initialise sodium");

    logInfo("Starting Summit");
    auto app = new SummitApp();
    app.start();
    scope (exit)
    {
        app.stop();
    }
    return runApplication();
}

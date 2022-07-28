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

int main(string[] args)
{
    const ret = sodium_init();
    enforce(ret == 0, "Failed to initialise sodium");

    auto app = new SummitApp();
    app.start();
    scope (exit)
    {
        app.stop();
    }
    return runApplication();
}

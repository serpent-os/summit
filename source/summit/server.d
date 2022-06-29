/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.server
 *
 * The primary runtime (vibe.d) process of our web server
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.server;

import vibe.vibe;

/**
 * Main vibe.d process
 */
public final class SummitServer
{

    this()
    {
        router = new URLRouter();
        /* TODO: Load stuff from config */
        settings = new HTTPServerSettings();
        settings.port = 8080;
        settings.bindAddresses = ["localhost",];

        /* Configure vibe.d to listen HTTP */
        listenHTTP(settings, router);
    }

    /**
     * Run server to completion
     */
    int run() @safe
    {
        /* We specifically do *not* use runApplication as we control
           our own privileges etc. */
        return runEventLoop();
    }

private:

    URLRouter router;
    HTTPServerSettings settings;

}

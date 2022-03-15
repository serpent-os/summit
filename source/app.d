/* SPDX-License-Identifier: Zlib */

/**
 * Main entry point
 *
 * Authors: © 2020-2022 Serpent OS Developers
 * License: ZLib
 */

module main;

import vibe.vibe;

/**
 * Simple entry point for now to help define styling
 */
final class SummitApp
{
    /**
     * Provide the main index page.
     */
    void index(HTTPServerRequest req, HTTPServerResponse res)
    {
        return res.render!"index.dt";
    }
}

/**
 * Main executable entry, bootstrap the server
 */
void main()
{
    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    auto router = new URLRouter();
    router.registerWebInterface(new SummitApp());
    auto listener = listenHTTP(settings, router);
    scope (exit)
    {
        listener.stopListening();
    }

    logInfo("Please open http://127.0.0.1:8080/ in your browser.");
    runApplication();
}

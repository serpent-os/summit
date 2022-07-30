/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web
 *
 * Root for all Web UI
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web;

import vibe.d;

import summit.web.accounts;
import summit.web.builders;
import summit.web.namespaces;
import summit.web.projects;

/**
 * Web interface providing the UI experience
 */
@path("/") public final class Web
{
    /**
     * Configure the web UI portions
     */
    void configure(URLRouter root) @safe
    {
        auto webRoot = root.registerWebInterface(this);
        webRoot.registerWebInterface(new AccountsWeb());
        webRoot.registerWebInterface(new BuildersWeb());
        webRoot.registerWebInterface(new ProjectsWeb());
        webRoot.registerWebInterface(new NamespacesWeb());
    }

    /**
     * Render the home page
     */
    void index()
    {
        render!("index.dt");
    }
}

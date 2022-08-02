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
import moss.db.keyvalue;

import summit.accounts;

/**
 * Web interface providing the UI experience
 */
@path("/") public final class Web
{
    /**
     * Configure the web UI portions
     */
    @noRoute void configure(URLRouter root, Database appDB, AccountManager accountsManager) @safe
    {
        auto webRoot = root.registerWebInterface(this);
        auto accts = new AccountsWeb();
        accts.configure(webRoot, accountsManager);
        auto ns = new NamespacesWeb();
        ns.configure(webRoot, appDB);
        webRoot.registerWebInterface(new BuildersWeb());
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

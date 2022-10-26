/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web
 *
 * Root web application (nested)
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web;

import vibe.d;
import summit.web.accounts;
import summit.web.collections;
import moss.service.accounts;
import moss.db.keyvalue;
import moss.client.metadb;

/**
 * Root entry into our web service
 */
@path("/")
public final class SummitWeb
{
    /**
     * Join SummitWeb into the router
     *
     * Params:
     *      appDB = Application database
     *      accountManager = Account management interface
     *      router = Base root for the application
     */
    @noRoute void configure(Database appDB, MetaDB metaDB,
            AccountManager accountManager, URLRouter router) @safe
    {
        auto root = registerWebInterface(router, this);
        auto act = new AccountsWeb(accountManager);
        act.configure(root);
        auto col = new CollectionsWeb();
        col.configure(appDB, metaDB, root);
    }

    /**
     * Return the "home" page
     */
    void index() @safe
    {
        render!"index.dt";
    }
}

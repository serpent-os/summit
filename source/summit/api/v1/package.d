/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1
 *
 * V1 Summit API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.api.v1;

public import vibe.d;
public import summit.api.v1.interfaces;
import moss.db.keyvalue;

import summit.api.v1.builders;
import summit.api.v1.collections;
import summit.api.v1.pairing;
import summit.api.v1.repositories;
import summit.api.v1.recipes;
import moss.service.tokens.manager;
import moss.service.accounts;

/**
 * Root implementation to configure all supported interfaces
 */
public final class RESTService : SummitAPIv1
{
    @disable this();

    /**
     * Construct the new RESTService root
     */
    this(string rootDir) @safe
    {
        this.rootDir = rootDir;
    }

    /**
     * Integrate the RESTService into the web application
     *
     * Params:
     *      appDB = Application database
     *      router = Root level router
     */
    @noRoute void configure(AccountManager accountManager,
            TokenManager tokenManager, Database appDB, URLRouter router) @safe
    {
        router.registerRestInterface(this);
        router.registerRestInterface(new BuildersService(accountManager, tokenManager, appDB));
        router.registerRestInterface(new CollectionsService(appDB));
        router.registerRestInterface(new RepositoriesService(appDB));
        router.registerRestInterface(new RecipesService(appDB));
        router.registerRestInterface(new PairingService(tokenManager, accountManager, appDB));
    }

    /**
     * Returns: Version identifier
     */
    override string versionID() @safe @nogc nothrow const
    {
        return "0.0.1";
    }

private:

    string rootDir;
}

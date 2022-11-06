/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.builders
 *
 * Builders Web API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.builders;

import vibe.d;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.models.endpoints;

/**
 * Root entry into our web service
 */
@path("/builders")
public final class BuildersWeb
{
    /**
     * Join BuildersWeb into the router
     *
     * Params:
     *      appDB = Application database
     *      router = Web root for the application
     */
    @noRoute void configure(Database appDB, URLRouter router) @safe
    {
        this.appDB = appDB;
        registerWebInterface(router, this);
    }

    /**
     * Builders index
     */
    void index() @safe
    {
        render!"builders/index.dt";
    }

private:

    Database appDB;
}

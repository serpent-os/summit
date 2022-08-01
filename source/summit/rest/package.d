/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.rest
 *
 * Root for all REST API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.rest;

import vibe.d;

import summit.accounts;
import summit.rest.builders;
import summit.rest.buildjobs;
import summit.rest.namespaces;
import moss.db.keyvalue;

@path("api/v1") public interface BaseAPIv1
{
    @path("version") @method(HTTPMethod.GET) string versionIdentifier() @safe;
}

/**
 * Web interface providing the UI experience
 */
public final class BaseAPI : BaseAPIv1
{
    /**
     * Prepare the BaseAPI for integration
     */
    @noRoute void configure(URLRouter root, Database appDB, AccountManager accountManager) @safe
    {
        auto apiRoot = root.registerRestInterface(this);
        auto nsAPI = new NamespacesAPI();
        nsAPI.configure(apiRoot, appDB);
        auto jobAPI = new BuildJobsAPI();
        jobAPI.configure(apiRoot, appDB, accountManager);
        auto bAPI = new BuilderAPI();
        bAPI.configure(apiRoot, appDB);
    }

    override string versionIdentifier() @safe
    {
        return "0.0.0";
    }
}

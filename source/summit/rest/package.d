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
    @noRoute void configure(URLRouter root, Database appDB) @safe
    {
        auto apiRoot = root.registerRestInterface(this);
        auto nsAPI = new NamespacesAPI();
        nsAPI.configure(apiRoot, appDB);
    }

    override string versionIdentifier() @safe
    {
        return "0.0.0";
    }
}

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

import summit.api.v1.collections;

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
     *      router = Root level router
     */
    @noRoute void configure(URLRouter router) @safe
    {
        router.registerRestInterface(this);
        router.registerRestInterface(new CollectionsService());
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

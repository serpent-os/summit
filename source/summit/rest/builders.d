/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.rest.builders
 *
 * API for Builders management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.rest.builders;

import vibe.d;

import summit.models.builder;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import std.array : array;

/**
 * The Builder API
 */
@path("api/v1/builders") public interface BuilderAPIv1
{
    /**
     * List all builders
     */
    @path("list") @method(HTTPMethod.GET) Builder[] list() @safe;

    /**
     * Add a new builder to the system
     */
    @path("add") @method(HTTPMethod.GET) void add(string hostname, string nick);
}

/**
 * Provide Builder management
 */
public final class BuilderAPI : BuilderAPIv1
{
    /**
     * Integrate into the root API
     */
    @noRoute void configure(URLRouter root, Database appDB) @safe
    {
        this.appDB = appDB;
        root.registerRestInterface(this);
    }

    /**
     * Grab all the known builders
     *
     * Returns: slice of Builders
     */
    override Builder[] list() @safe
    {
        Builder[] jobs;
        appDB.view((in tx) @safe {
            /* TODO: Filter */
            jobs = tx.list!Builder().array;
            return NoDatabaseError;
        });
        return jobs;
    }

    /**
     * Add a new builder
     */
    override void add(string hostname, string nick) @safe
    {
        Builder b = Builder(0, hostname, nick, [], BuilderStatus.Unconfigured);
        auto err = appDB.update((scope tx) => b.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
    }

private:

    Database appDB;
}

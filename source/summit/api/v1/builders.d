/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.builders
 *
 * V1 Summit Builders API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.builders;

public import summit.api.v1.interfaces;
import vibe.d;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.models.endpoints;
import moss.service.interfaces;
import std.algorithm : map;
import std.array : array;
import summit.workers;

/**
 * Implements the BuildersService
 */
public final class BuildersService : BuildersAPIv1
{
    @disable this();

    /**
     * Construct new BuildersService
     */
    this(scope WorkerSystem workerSystem, Database appDB) @safe
    {
        this.appDB = appDB;
        queue = workerSystem.controlQueue;
    }

    /**
     * Enumerate all of the builders
     *
     * Returns: ListItem[] of known builders
     */
    override ListItem[] enumerate() @safe
    {
        ListItem[] ret;
        appDB.view((in tx) @safe {
            auto items = tx.list!AvalancheEndpoint
                .map!((i) {
                    ListItem v;
                    v.context = ListContext.Builders;
                    v.id = i.id;
                    v.title = i.id;
                    v.subtitle = i.description;
                    return v;
                });
            ret = () @trusted { return items.array; }();
            return NoDatabaseError;
        });
        return ret;
    }

    /**
     * Create a new avalanche attachment
     *
     * Params:
     *      request = Incoming request
     */
    override void create(AttachAvalanche request) @safe
    {
        logDiagnostic(format!"Incoming attachment: %s"(request));

        /* TODO: Mark as unused */
        AvalancheEndpoint endpoint;
        endpoint.adminEmail = request.adminEmail;
        endpoint.adminName = request.adminName;
        endpoint.hostAddress = request.instanceURI;
        endpoint.publicKey = request.pubkey;
        endpoint.description = request.summary;
        endpoint.id = request.id;

        immutable err = appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

private:
    Database appDB;
    ControlQueue queue;
}

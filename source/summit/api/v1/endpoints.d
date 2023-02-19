/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.endpoints
 *
 * V1 Summit Endpoints API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.endpoints;

public import summit.api.v1.interfaces;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import moss.service.models.endpoints;
import std.algorithm : map;
import std.array : array;
import vibe.d;

/**
 * Implements the EndpointsAPIv1
 */
public final class EndpointsService : EndpointsAPIv1
{
    @disable this();

    /**
     * Construct new EndpointsService
     *
     * Params:
     *      context = global context
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /**
     * Enumerate all of the endpoints
     *
     * Returns: ListItem[] of known endpoints
     */
    override ListItem[] enumerate() @safe
    {
        ListItem[] ret;
        context.appDB.view((in tx) @safe {
            auto items = tx.list!VesselEndpoint
                .map!((i) {
                    ListItem v;
                    v.context = ListContext.Endpoints;
                    v.id = i.id;
                    v.title = i.id;
                    v.subtitle = i.description;
                    v.status = i.status;
                    return v;
                });
            ret = () @trusted { return items.array; }();
            return NoDatabaseError;
        });
        return ret;
    }

    /**
     * Create a new endpoint attachment
     *
     * Params:
     *      request = Creation request
     */
    override void create(AttachEndpoint request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "DERP");
    }

private:
    ServiceContext context;
}

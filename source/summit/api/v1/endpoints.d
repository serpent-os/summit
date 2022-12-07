/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.endpoints
 *
 * V1 Summit Endpoints API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.endpoints;

public import summit.api.v1.interfaces;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.context;
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
    this(SummitContext context) @safe
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
        return null;
    }

    /**
     * Create a new endpoint attachment
     *
     * Params:
     *      request = Creation request
     */
    override void create(AttachVessel request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "DERP");
    }

private:
    SummitContext context;
}

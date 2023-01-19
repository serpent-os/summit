/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.pairing
 *
 * Implementation of service enrolment
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.api.v1.pairing;

public import moss.service.interfaces;

import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import moss.service.models;
import vibe.d;

/**
 * Implementation of the hub-aspect enrolment API
 */
public final class PairingService : ServiceEnrolmentAPI
{
    @disable this();

    mixin AppAuthenticatorContext;

    /** 
     * Construct new pairing API
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
    }

    override void enrol(ServiceEnrolmentRequest request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "Summit does not support .enrol()");
    }

    override string refreshToken(NullableToken token) @safe
    {
        return "";
    }

    override string refreshIssueToken(NullableToken token) @safe
    {
        return "";
    }

    override void accept(ServiceEnrolmentRequest request, NullableToken token) @safe
    {
        /* We can handle avalanche and vessel requests only */
        switch (token.payload.aud)
        {
        case "avalanche":
            AvalancheEndpoint endpoint;
            immutable err = context.appDB.view((in tx) => endpoint.load(tx, token.payload.sub));
            enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
            endpoint.status = EndpointStatus.Operational;
            endpoint.bearerToken = request.issueToken;
            immutable errStore = context.appDB.update((scope tx) => endpoint.save(tx));
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
            logInfo(format!"Completed pairing of %s via token %s"(request, token.get));
            break;
        default:
            throw new HTTPStatusException(HTTPStatus.badRequest, "Unsupported token audience");
        }
    }

    override void decline(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "decline(): Not yet implemented");
    }

    override void leave(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "leave(): Not yet implemented");
    }

    /**
     * TODO: Replace builder enumeration code?
     */
    override VisibleEndpoint[] enumerate() @safe
    {
        return null;
    }

private:

    ServiceContext context;
}

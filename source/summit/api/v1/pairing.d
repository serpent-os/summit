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
import moss.service.tokens;
import vibe.d;
import moss.service.pairing;

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
    this(ServiceContext context, PairingManager pairingManager) @safe
    {
        this.context = context;
        this.pairingManager = pairingManager;
    }

    override void enrol(ServiceEnrolmentRequest request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "Summit does not support .enrol()");
    }

    /** 
     * Handle client request to re-issue an API token
     *
     * Client auth is already handled via moss-service via AppAuthenticatorContext
     *
     * Params:
     *   token = The client token
     * Returns: A new API token if possible
     */
    override string refreshToken(NullableToken token) @safe
    {
        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        TokenPayload payload;
        payload.iss = "summit";
        payload.sub = token.payload.sub;
        payload.aud = token.payload.aud;
        payload.admin = token.payload.admin;
        payload.uid = token.payload.uid;
        payload.act = token.payload.act;
        Token refreshedToken = context.tokenManager.createAPIToken(payload);
        return context.tokenManager.signToken(refreshedToken).tryMatch!((string s) => s);
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
            acceptEndpoint(endpoint, request, token);
            break;
        case "vessel":
            VesselEndpoint endpoint;
            acceptEndpoint(endpoint, request, token);
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

    void acceptEndpoint(E)(ref E endpoint, ServiceEnrolmentRequest request, NullableToken token) @safe
    {
        immutable err = context.appDB.view((in tx) => endpoint.load(tx, token.payload.sub));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
        endpoint.status = EndpointStatus.Operational;
        endpoint.bearerToken = request.issueToken;
        immutable errStore = context.appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        logInfo(format!"Completed pairing of %s via token %s"(request, token.get));
    }

    ServiceContext context;
    PairingManager pairingManager;
}

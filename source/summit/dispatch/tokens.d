/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.dispatch.tokens
 *
 * Token management for integration in dispatch
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.dispatch.tokens;

import moss.service.context;
import moss.service.models;
import moss.service.interfaces.endpoints;
import moss.service.tokens;
import vibe.d;

/** 
 * Check if a token is within a given validity range
 *
 * Params:
 *   encodedAPIToken = Some encoded token string
 *   tolerableDiff = How fresh we need the token
 * Returns: true if the token is within the expressed range
 */
static bool tokenWithinRange(string encodedAPIToken, ulong tolerableDiff) @safe
{
    auto timeNow = Clock.currTime(UTC()).toUnixTime;
    if (encodedAPIToken.empty)
    {
        return false;
    }

    return Token.decode(encodedAPIToken)
        .match!((Token tk) => timeNow + tolerableDiff <= tk.payload.exp, (_) => false);
}

/**
 * Internal helper to assist with getting bearer + issue tokens
 */
static bool obtainToken(E, bool bearer)(ref E endpoint, ServiceContext context) @safe
{
    auto api = new RestInterfaceClient!ServiceEnrolmentAPI(endpoint.hostAddress);
    api.requestFilter = (req) {
        req.headers["Authorization"] = format!"Bearer %s"(endpoint.bearerToken);
    };

    static if (bearer)
    {
        string tokenDescriptor = "bearerToken";
    }
    else
    {
        string tokenDescriptor = "apiToken";
    }

    logInfo(format!"[%s] Refreshing %s instance '%s'"(tokenDescriptor, E.stringof, endpoint.id));
    string assignedToken;
    try
    {
        static if (bearer)
        {
            assignedToken = api.refreshIssueToken(NullableToken());
        }
        else
        {
            assignedToken = api.refreshToken(NullableToken());
        }
    }
    catch (Exception ex)
    {
        logError(format!"[%s] Failed to refresh %s '%s': %s"(tokenDescriptor,
                E.stringof, endpoint.id, ex.message));
    }

    if (assignedToken.empty)
    {
        endpoint.status = EndpointStatus.Unreachable;
        static if (bearer)
        {
            endpoint.statusText = "Failed to refresh bearer token";
        }
        else
        {
            endpoint.statusText = "Failed to refresh API token";
            endpoint.apiToken = null;
        }
    }
    else
    {
        /* Is this a valid token from that instance? */
        bool usableToken = Token.decode(assignedToken).match!((Token tk) {
            try
            {
                context.tokenManager.verify(tk, endpoint.publicKey);
                return true;
            }
            catch (Exception ex)
            {
                logError(format!"[%s] Illegal signature from %s instance '%s': %s"(tokenDescriptor,
                    E.stringof, endpoint.id, ex.message));
                endpoint.statusText = "Illegal signature";
                return false;
            }
        }, (TokenError err) {
            logError(format!"[%s] Invalid token issued by %s instance '%s': %s"(tokenDescriptor,
                E.stringof, endpoint.id, err.message));
            endpoint.statusText = "Invalid token";
            return false;
        });

        /* Ban from use if necessary */
        if (!usableToken)
        {
            endpoint.status = EndpointStatus.Forbidden;
            endpoint.apiToken = null;
        }
        else
        {
            endpoint.status = EndpointStatus.Operational;
            static if (bearer)
            {
                endpoint.bearerToken = assignedToken;
            }
            else
            {
                endpoint.apiToken = assignedToken;
            }
            logInfo(format!"[%s] New token issued by %s instance '%s'"(tokenDescriptor,
                    E.stringof, endpoint.id));
        }
    }

    /* Update the model with usability status */
    immutable err = context.appDB.update((scope tx) => endpoint.save(tx));
    enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    return !endpoint.apiToken.empty;
}

/**
 * Obtain a fresh bearer token from an endpoint instance
 *
 * Note, if we're suffering clock desync issues and our bearer token is invalid,
 * we may end up marking an endpoint unreachable to keep the implementation
 * simpler.
 *
 * Params:
 *      E = Some Endpoint type in moss-service
 *      endpoint = Endpoint we're getting a bearer token for
 *      context = Global service context
 * Returns: True if we retreived a usable bearer token
 */
static bool obtainBearerToken(E)(ref E endpoint, ServiceContext context) @safe
{
    return obtainToken!(E, true)(endpoint, context);
}

/**
 * Obtain an API token from an endpoint instance.
 *
 * Note, if we're suffering clock desync issues and our bearer token is invalid,
 * we may end up marking an endpoint unreachable to keep the implementation
 * simpler.
 *
 * Params:
 *      E = Some Endpoint type in moss-service
 *      endpoint = Endpoint we're getting an API token for
 *      context = Global service context
 * Returns: True if we retreived a usable API token
 */
static bool obtainAPIToken(E)(ref E endpoint, ServiceContext context) @safe
{
    return obtainToken!(E, false)(endpoint, context);
}

/**
 * Ascertain the endpoint usability
 *
 * If we have an unexpired issue token, we'll consider this as
 * usable and proceed. Otherwise, attempt various forms of token
 * refresh.
 *
 * If token refresh fails, the endpoint is unusable. At that point
 * the job needs to be failed and rescheduled, while marking the
 * builder as down.
 *
 * The endpoint will need to send a heartbeat event again to be marked
 * reachable once more.
 *
 * Params:
 *      E = Endpoint type
 *      endpoint = valid endpoint
 *      context = global shared context
 * Returns: True if the endpoint is usable (may be forced to be)
 */
bool ensureEndpointUsable(E)(ref E endpoint, ServiceContext context) @safe
{
    immutable static validity = 15 * 60;

    /* Ensure bearer token is valid */
    if (!tokenWithinRange(endpoint.bearerToken, validity))
    {
        if (!obtainBearerToken(endpoint, context))
        {
            return false;
        }
    }
    if (!tokenWithinRange(endpoint.apiToken, validity))
    {
        return obtainAPIToken(endpoint, context);
    }
    return true;
}

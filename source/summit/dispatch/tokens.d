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
        return true;
    }

    return Token.decode(encodedAPIToken)
        .match!((Token tk) => timeNow + tolerableDiff >= tk.payload.exp, (_) => false);
}

/**
 * Obtain an API token from an Avalanche instance.
 *
 * Note, if we're suffering clock desync issues and our bearer token is invalid,
 * we may end up marking an endpoint unreachable to keep the implementation
 * simpler.
 *
 * Params:
 *      endpoint = Endpoint we're getting an API token for
 *      context = Global service context
 * Returns: True if we retreived a usable API token
 */
static bool obtainAvalancheAPIToken(ref AvalancheEndpoint endpoint, ServiceContext context) @safe
{
    auto api = new RestInterfaceClient!ServiceEnrolmentAPI(endpoint.hostAddress);
    api.requestFilter = (req) {
        req.headers["Authorization"] = format!"Bearer %s"(endpoint.bearerToken);
    };

    logInfo(format!"[apitoken] Refreshing Avalanche instance '%s'"(endpoint.id));
    string assignedToken;
    try
    {
        assignedToken = api.refreshToken(NullableToken());
    }
    catch (Exception ex)
    {
        logError(format!"[apitoken] Failed to refresh Avalanche instance '%s': %s"(endpoint.id,
                ex.message));
    }

    if (assignedToken.empty)
    {
        endpoint.status = EndpointStatus.Unreachable;
        endpoint.statusText = "Failed to get an API token";
        endpoint.apiToken = null;
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
                logError(format!"[apitoken] Illegal signature from Avalanche instance '%s': %s"(endpoint.id,
                    ex.message));
                endpoint.statusText = "Illegal signature";
                return false;
            }
        }, (TokenError err) {
            logError(format!"[apitoken] Invalid token issued by Avalanche instance '%s': %s"(endpoint.id,
                err.message));
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
            endpoint.apiToken = assignedToken;
            logInfo(format!"[apitoken] New API token issued by Avalanche instance '%s'"(
                    endpoint.id));
        }
    }

    /* Update the model with usability status */
    immutable err = context.appDB.update((scope tx) => endpoint.save(tx));
    enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    return !endpoint.apiToken.empty;
}

/**
 * Ascertain the builder usability
 *
 * If we have an unexpired issue token, we'll consider this as
 * usable and proceed. Otherwise, attempt various forms of token
 * refresh.
 *
 * If token refresh fails, the endpoint is unusable. At that point
 * the job needs to be failed and rescheduled, while marking the
 * builder as down.
 *
 * The builder will need to send a heartbeat event again to be marked
 * reachable once more.
 */
bool builderUsable(ref AvalancheEndpoint endpoint, ServiceContext context) @safe
{
    immutable static validity = 15 * 60;

    /* Ensure bearer token is valid */
    if (!tokenWithinRange(endpoint.bearerToken, validity))
    {
        return false;
    }
    if (!tokenWithinRange(endpoint.apiToken, validity))
    {
        return obtainAvalancheAPIToken(endpoint, context);
    }
    return true;
}

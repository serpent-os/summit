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
import moss.service.tokens;
import moss.service.tokens.manager;

/**
 * Implements the BuildersService
 */
public final class BuildersService : BuildersAPIv1
{
    @disable this();

    /**
     * Construct new BuildersService
     */
    this(scope WorkerSystem workerSystem, TokenManager tokenManager, Database appDB) @safe
    {
        this.appDB = appDB;
        this.tokenManager = tokenManager;
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
        endpoint.status = EndpointStatus.AwaitingEnrolment;
        endpoint.adminEmail = request.adminEmail;
        endpoint.adminName = request.adminName;
        endpoint.hostAddress = request.instanceURI;
        endpoint.publicKey = request.pubkey;
        endpoint.description = request.summary;
        endpoint.id = request.id;

        immutable err = appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Get token allocated */
        EnrolAvalancheEvent event = EnrolAvalancheEvent(endpoint);
        TokenPayload payload;
        payload.iss = "summit";
        payload.sub = endpoint.id;
        Token bearer = tokenManager.createBearerToken(payload);
        tokenManager.signToken(bearer).match!((TokenError err) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, err.message);
        }, (string s) { event.issueToken = s; });
        event.instancePublicKey = tokenManager.publicKey;

        /* Dispatch the event */
        queue.put(ControlEvent(event));
    }

private:
    Database appDB;
    ControlQueue queue;
    TokenManager tokenManager;
}

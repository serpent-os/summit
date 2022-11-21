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
import moss.service.models.bearertoken;
import moss.service.models.endpoints;
import summit.models.settings;
import moss.service.interfaces;
import std.algorithm : map;
import std.array : array;
import summit.workers;
import moss.service.tokens;
import moss.service.tokens.manager;
import moss.service.accounts;

/**
 * Implements the BuildersService
 */
public final class BuildersService : BuildersAPIv1
{
    @disable this();

    /**
     * Construct new BuildersService
     */
    this(scope WorkerSystem workerSystem, AccountManager accountManager,
            TokenManager tokenManager, Database appDB) @safe
    {
        this.appDB = appDB;
        this.tokenManager = tokenManager;
        this.accountManager = accountManager;
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

        /* OK - first up we need a service account */
        immutable serviceUser = format!"%s%s"(serviceAccountPrefix, request.id);
        Account serviceAccount;
        accountManager.registerService(serviceUser, request.adminEmail).match!((Account u) {
            serviceAccount = u;
        }, (DatabaseError e) {
            throw new HTTPStatusException(HTTPStatus.forbidden, e.message);
        });

        logInfo(format!"Constructed new service account '%s': %s"(serviceAccount.id, serviceUser));

        /**
         * Construct the bearer token
         * NOTE:
         *  aud = avalanche ALWAYS
         *  sub = `request.id` - so we can map to AvalancheEndpoint in the DB
         * This varies from user accounts where `sub` = `username`
         */
        string encodedToken;
        TokenPayload payload;
        payload.iss = "summit";
        payload.sub = request.id;
        payload.uid = serviceAccount.id;
        payload.act = serviceAccount.type;
        payload.aud = "avalanche";
        Token bearer = tokenManager.createBearerToken(payload);
        tokenManager.signToken(bearer).match!((TokenError err) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, err.message);
        }, (string s) { encodedToken = s; });

        /* Set the token in the DB now */
        BearerToken storedToken;
        storedToken.id = serviceAccount.id;
        storedToken.rawToken = encodedToken;
        storedToken.expiryUTC = bearer.payload.exp;
        immutable bErr = accountManager.setBearerToken(serviceAccount, storedToken);

        /* Create the endpoint model */
        AvalancheEndpoint endpoint;
        endpoint.serviceAccount = serviceAccount.id;
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
        event.issueToken = encodedToken;
        event.instancePublicKey = tokenManager.publicKey;

        Settings settings = appDB.getSettings().tryMatch!((Settings s) => s);
        event.instanceURI = settings.instanceURI;

        /* Dispatch the event */
        queue.put(ControlEvent(event));
    }

private:
    Database appDB;
    ControlQueue queue;
    TokenManager tokenManager;
    AccountManager accountManager;
}

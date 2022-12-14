/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.builders
 *
 * V1 Summit Builders API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.builders;

public import summit.api.v1.interfaces;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import moss.service.interfaces;
import moss.service.models.bearertoken;
import moss.service.models.endpoints;
import moss.service.tokens;
import std.algorithm : map;
import std.array : array;
import summit.models.settings;
import vibe.d;

/**
 * Implements the BuildersService
 */
public final class BuildersService : BuildersAPIv1
{
    @disable this();

    /**
     * Construct new BuildersService
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /**
     * Enumerate all of the builders
     *
     * Returns: ListItem[] of known builders
     */
    override ListItem[] enumerate() @safe
    {
        ListItem[] ret;
        context.appDB.view((in tx) @safe {
            auto items = tx.list!AvalancheEndpoint
                .map!((i) {
                    ListItem v;
                    v.context = ListContext.Builders;
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
     * Create a new avalanche attachment
     *
     * Params:
     *      request = Incoming request
     * Throws: HTTPStatusException on credential failure
     */
    override void create(AttachAvalanche request) @safe
    {
        logDiagnostic(format!"Incoming attachment: %s"(request));

        /* OK - first up we need a service account */
        immutable serviceUser = format!"%s%s"(serviceAccountPrefix, request.id);
        Account serviceAccount;
        context.accountManager.registerService(serviceUser, request.adminEmail).match!((Account u) {
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
        Token bearer = context.tokenManager.createBearerToken(payload);
        context.tokenManager.signToken(bearer).match!((TokenError err) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, err.message);
        }, (string s) { encodedToken = s; });

        /* Set the bearer token in the DB now */
        BearerToken storedToken;
        storedToken.id = serviceAccount.id;
        storedToken.rawToken = encodedToken;
        storedToken.expiryUTC = bearer.payload.exp;
        immutable bErr = context.accountManager.setBearerToken(serviceAccount, storedToken);

        /* Create the endpoint model */
        AvalancheEndpoint endpoint;
        endpoint.serviceAccount = serviceAccount.id;
        endpoint.status = EndpointStatus.AwaitingAcceptance;
        endpoint.statusText = "Newly added";
        endpoint.adminEmail = request.adminEmail;
        endpoint.adminName = request.adminName;
        endpoint.hostAddress = request.instanceURI;
        endpoint.publicKey = request.pubkey;
        endpoint.description = request.summary;
        endpoint.id = request.id;
        immutable err = context.appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Sort out the enrolment request */
        const settings = context.appDB.getSettings().tryMatch!((Settings s) => s);
        ServiceEnrolmentRequest req;
        req.role = EnrolmentRole.Builder;
        req.issueToken = encodedToken;
        req.issuer.publicKey = context.tokenManager.publicKey;
        req.issuer.role = EnrolmentRole.Hub;
        req.issuer.url = settings.instanceURI;

        /* This may take some time, timeout, etc, so don't block the response waiting for
         * something to happen. */
        runTask({
            auto api = new RestInterfaceClient!ServiceEnrolmentAPI(endpoint.hostAddress);
            try
            {
                api.enrol(req);
                endpoint.status = EndpointStatus.AwaitingAcceptance;
                endpoint.statusText = "Awaiting acceptance";
            }
            catch (RestException rx)
            {
                endpoint.status = EndpointStatus.Failed;
                endpoint.statusText = format!"Negotiation failure: %s"(rx.message);
            }
            immutable err = context.appDB.update((scope tx) => endpoint.save(tx));
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        });
    }

private:

    ServiceContext context;
}

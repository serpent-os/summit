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
import moss.core.errors;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import moss.service.interfaces;
import moss.service.models.bearertoken;
import moss.service.models.endpoints;
import moss.service.pairing;
import moss.service.tokens;
import std.algorithm : map;
import std.array : array;
import std.sumtype;
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
    this(ServiceContext context, PairingManager pairingManager) @safe
    {
        this.context = context;
        this.pairingManager = pairingManager;
    }

    mixin AppAuthenticatorContext;

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
    override void create(AttachEndpoint request) @safe
    {
        logDiagnostic(format!"Incoming avalanche attachment: %s"(request));

        AvalancheEndpoint endpoint;
        endpoint.adminEmail = request.adminEmail;
        endpoint.adminName = request.adminName;
        endpoint.hostAddress = request.instanceURI;
        endpoint.id = request.id;
        endpoint.publicKey = request.pubkey;
        endpoint.description = request.summary;

        /* Begin by creating an account */
        pairingManager.createEndpointAccount(endpoint).match!((Account serviceAccount) {
            /* Assign a bearer token */
            pairingManager.createBearerToken(endpoint, serviceAccount,
                "avalanche").match!((BearerToken bearerToken) {
                /* Send the enrolment */
                pairingManager.enrolWith(endpoint, bearerToken,
                EnrolmentRole.Hub, EnrolmentRole.Builder).match!((Success _) {
                    logInfo(format!"Builder Enrolment sent to %s"(endpoint.hostAddress));
                }, (Failure f) {
                    logInfo(format!"Failed to enrol builder '%s': %s"(endpoint.id, f.message));
                });
            }, (Failure f) {
                logError(format!"Failed to create bearer token: %s"(f.message));
            });
        }, (DatabaseError err) {
            logError(format!"Failed to create service account %s"(err.message));
        });
    }

private:

    ServiceContext context;
    PairingManager pairingManager;
}

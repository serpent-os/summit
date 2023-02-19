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
import moss.service.interfaces;
import moss.service.models;
import moss.service.pairing;
import std.algorithm : map;
import std.array : array;
import vibe.d;
import moss.core.errors;

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
    this(ServiceContext context, PairingManager pairingManager) @safe
    {
        this.context = context;
        this.pairingManager = pairingManager;
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
        logDiagnostic(format!"Incoming vessel attachment: %s"(request));

        VesselEndpoint endpoint;
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
                "vessel").match!((BearerToken bearerToken) {
                /* Send the enrolment */
                pairingManager.enrolWith(endpoint, bearerToken, EnrolmentRole.Hub,
                EnrolmentRole.RepositoryManager).match!((Success _) {
                    logInfo(format!"Vessel Enrolment sent to %s"(endpoint.hostAddress));
                }, (Failure f) {
                    logInfo(format!"Failed to enrol vessel '%s': %s"(endpoint.id, f.message));
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

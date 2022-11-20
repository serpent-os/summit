/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.workers.handlers.pairing
 *
 * Pairing support
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.workers.handlers.pairing;

public import summit.workers.messaging;
public import summit.workers.handlers : HandlerContext;

import vibe.d;
import moss.service.interfaces;

/**
 * Handle a request for enroling a new builder
 *
 * Params:
 *      context = Handling context
 *      event = the EnrolAvalancheEvent
 */
public void handleEnrolBuilder(scope HandlerContext context, scope const ref ControlEvent event) @safe
{
    EnrolAvalancheEvent enrol = cast(EnrolAvalancheEvent) event;
    logInfo(format!"Got a request to enrol %s"(enrol.endpoint));

    /* TODO: Make this more complete. */
    ServiceEnrolmentRequest req;
    req.role = EnrolmentRole.Builder;
    req.issueToken = enrol.issueToken;
    req.issuer.publicKey = enrol.instancePublicKey;
    req.issuer.role = EnrolmentRole.Hub;
    req.issuer.url = enrol.instanceURI;
    /* Enrol with the remote system */
    auto api = new RestInterfaceClient!ServiceEnrolmentAPI(event.endpoint.hostAddress);
    api.enrol(req);
}

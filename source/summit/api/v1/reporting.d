/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.reporting
 *
 * V1 Summit Reporting API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.reporting;

import moss.service.interfaces.summit;
import moss.service.context;
import summit.models.buildtask : BuildTaskID;
import vibe.d;
import summit.dispatch.worker : DispatchChannel;
import summit.dispatch.messaging;

/** 
 * The reporting service is communicated with by Avalanche + Vessel
 * to let Summit know when it's ok to proceed with build queues.
 */
public final class ReportingService : SummitAPI
{
    @disable this();

    mixin AppAuthenticatorContext;

    /** 
     * Create new reporting service
     *
     * Params:
     *   context = global shared context
     *   channel = Control channel to integrate with DispatchWorker
     */
    this(ServiceContext context, DispatchChannel channel) @safe
    {
        this.context = context;
        this.channel = channel;
    }

    override void buildFailed(BuildTaskID taskID, NullableToken token) @safe
    {
        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        enforceHTTP(token.payload.aud == "avalanche", HTTPStatus.forbidden);

        /* Dispatch to the worker */
        DispatchEvent event = BuildFailedEvent(taskID, token.payload.sub);
        channel.put(event);
    }

    override void buildSucceeded(BuildTaskID taskID, NullableToken token) @safe
    {
        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        enforceHTTP(token.payload.aud == "avalanche", HTTPStatus.forbidden);
        logInfo(format!"Avalanche reports the build has succeeded: #%s"(taskID));

        /* Dispatch to the worker */
        DispatchEvent event = BuildSucceededEvent(taskID, token.payload.sub);
        channel.put(event);
    }

private:

    ServiceContext context;
    DispatchChannel channel;
}

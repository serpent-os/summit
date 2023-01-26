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
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
    }

    override void buildFailed(BuildTaskID taskID, NullableToken token) @safe
    {
        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        enforceHTTP(token.payload.aud == "avalanche", HTTPStatus.forbidden);
        logError(format!"Avalanche reports the build has failed: #%s"(taskID));
    }

    override void buildSucceeded(BuildTaskID taskID, NullableToken token) @safe
    {
        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        enforceHTTP(token.payload.aud == "avalanche", HTTPStatus.forbidden);
        logInfo(format!"Avalanche reports the build has succeeded: #%s"(taskID));
    }

private:

    ServiceContext context;
}

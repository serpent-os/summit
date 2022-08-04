/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

module summit.workers.async_worker;

/**
 * summit.workers
 *
 * Implements the worker bee system (Task scheduling)
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

import vibe.d;
import vibe.core.channel;
import vibe.core.core : yield;

public import summit.workers.job;

/**
 * Our threaded helper
 *
 * Params:
 *      incoming = Incoming work
 */
public static void workerFunction(ref WorkerChannel incoming) @safe nothrow
{
    WorkerTask job;

    /**
     * Pull items from the channel to work on
     */
    while (incoming.tryConsumeOne(job))
    {
        logInfo(" >>> Got a job: %s", job);
    }

    logInfo(" >>> Stopping worker thread: %s", thisTid());
}

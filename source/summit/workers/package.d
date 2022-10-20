/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.workers
 *
 * Workers module
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.workers;

import vibe.d;

/**
 * The WorkerSystem is responsible for managing dispatch and
 * control for various workers.
 */
public final class WorkerSystem
{
    @disable this();

    /**
     * The WorkerSystem is created with a root directory
     */
    this(string rootDir) @safe
    {
        this.rootDir = rootDir;
    }

    /**
     * Shutdown the worker system
     */
    void close() @safe
    {
        logInfo("WorkerSystem shutting down");
    }

private:

    string rootDir;
}

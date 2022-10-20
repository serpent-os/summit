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
import summit.workers.messaging;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;

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
    this(string rootDir, Database appDB) @safe
    {
        this.rootDir = rootDir;
        this.appDB = appDB;
        controlQueue = createChannel!(ControlEvent, numEvents)();
    }

    /**
     * Shutdown the worker system
     */
    void close() @safe
    {
        logInfo("WorkerSystem shutting down");
        controlQueue.close();
    }

private:

    string rootDir;
    ControlQueue controlQueue;
    Database appDB;
}

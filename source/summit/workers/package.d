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
public import summit.workers.messaging;
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
        _controlQueue = createChannel!(ControlEvent, numEvents)();
    }

    /**
     * Process the queue in parallel green thread
     */
    void start() @safe
    {
        logInfo("WorkerSystem started");
        runTask({
            ControlEvent event;
            while (controlQueue.tryConsumeOne(event))
            {
                logDiagnostic(format!"Worker system: Event [%s]"(event.kind));
            }
        });
    }

    /**
     * Shutdown the worker system
     */
    void close() @safe
    {
        logInfo("WorkerSystem shutting down");
        _controlQueue.close();
    }

    /**
     * Returns: The controlQueue
     */
    pure @property auto controlQueue() @safe @nogc nothrow
    {
        return _controlQueue;
    }

private:

    string rootDir;
    ControlQueue _controlQueue;
    Database appDB;
}

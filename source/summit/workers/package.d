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

public import summit.workers.messaging;
import moss.client.metadb;
import moss.core.errors;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.workers.handlers;
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
    this(string rootDir, Database appDB, MetaDB metaDB) @safe
    {
        this.rootDir = rootDir;
        this.appDB = appDB;
        this.metaDB = metaDB;
        _controlQueue = createChannel!(ControlEvent, numEvents)();
        greenQueue = createChannel!(ControlEvent, numEvents)();
        distributedQueue = createChannel!(ControlEvent, numEvents)();
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
                switch (event.kind)
                {
                case ControlEvent.Kind.scanManifests:
                    /* Expensive mmap bulk scanning */
                    distributedQueue.put(event);
                    break;
                default:
                    /* Put to the green queue (vibe I/O) */
                    greenQueue.put(event);
                    break;
                }
            }
        });

        /* Set up the context */
        HandlerContext ct;
        ct.serialQueue = greenQueue;
        ct.rootDirectory = rootDir;

        runTask(&processGreenQueue, ct);
        runWorkerTaskDist(&processDistributedQueue, ct, distributedQueue);
    }

    /**
     * Shutdown the worker system
     */
    void close() @safe
    {
        logInfo("WorkerSystem shutting down");
        _controlQueue.close();
        greenQueue.close();
        distributedQueue.close();
    }

    /**
     * Returns: The controlQueue
     */
    pure @property auto controlQueue() @safe @nogc nothrow
    {
        return _controlQueue;
    }

private:

    /**
     * Import a specific manifest
     *
     * Params:
     *      event = Import event
     */
    void importManifest(ImportManifestEvent event) @safe
    {
        logDiagnostic(format!"Importing manifest %s into %s"(event.manifestPath, event.repo.name));
    }

    /** 
     * Update repository metadata (thread-safe)
     *
     * Params:
     *      event = Repository that needs updating
     */
    void updateRepo(UpdateRepositoryEvent event) @safe
    {
        Repository oldData;
        immutable lookupErr = appDB.view((in tx) => oldData.load(tx, event.repo.id));
        immutable err = appDB.update((scope tx) => event.repo.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        logDiagnostic(format!"Updated repo data: %s"(event.repo));

        if (lookupErr.isNull && oldData.commitRef != event.repo.commitRef)
        {
            logDiagnostic(format!"Scheduling scan for %s"(event.repo));
            _controlQueue.put(ControlEvent(ScanManifestsEvent(event.repo)));
        }
    }

    /**
     * Process the green queue (multiplexed fibers)
     */
    void processGreenQueue(HandlerContext context) @safe
    {
        ControlEvent event;
        while (greenQueue.tryConsumeOne(event))
        {
            logInfo(format!"greenQueue: Event [%s]"(event.kind));

            switch (event.kind)
            {
            case ControlEvent.Kind.updateRepo:
                updateRepo(cast(UpdateRepositoryEvent) event);
                break;
            case ControlEvent.Kind.importManifest:
                importManifest(cast(ImportManifestEvent) event);
                break;
            default:
                processEvent(context, event);
                break;
            }
        }
        logInfo("greenQueue: Finished");
    }

    /**
     * Handler for the distributed queue
     *
     * Params:
     *      context = Handling context
     *      queue = Dispatch queue
     */
    static void processDistributedQueue(HandlerContext context, ControlQueue queue) @safe
    {
        ControlEvent event;
        while (queue.tryConsumeOne(event))
        {
            logInfo(format!"distributedQueue: Event [%s]"(event.kind));
            processEvent(context, event);
        }
        logInfo("distributedQueue: Finished");
    }

    string rootDir;
    ControlQueue _controlQueue;

    /* Multiple threads read from distributed queue */
    ControlQueue distributedQueue;

    /* main thread pulling from a serial queue */
    ControlQueue greenQueue;

    Database appDB;
    MetaDB metaDB;
}

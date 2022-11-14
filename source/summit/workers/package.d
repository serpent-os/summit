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
import moss.format.source.spec;
import moss.format.binary.reader;
import moss.format.binary.payload.meta;
import moss.core.util : computeSHA256;
import std.path : buildPath, dirName, relativePath;
import std.algorithm : uniq, sort;

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
    void importManifest(ImportManifestEvent event) @trusted
    {
        scope rdr = new Reader(File(event.manifestPath, "rb"));
        auto payloads = rdr.payloads!MetaPayload;
        if (payloads.empty)
        {
            logWarn(format!"Missing payloads in manifest %s"(event.manifestPath));
            return;
        }

        logDiagnostic(format!"Importing manifest %s into %s"(event.manifestPath, event.repo.name));
        MetaPayload mp = new MetaPayload();
        mp.addRecord(RecordType.String, RecordTag.SourceRef, event.repo.commitRef);
        mp.addRecord(RecordType.String, RecordTag.SourceURI, event.repo.originURI);
        immutable ymlPath = event.manifestPath.dirName.buildPath("stone.yml");
        immutable checksum = computeSHA256(event.manifestPath, true);
        mp.addRecord(RecordType.String, RecordTag.PackageHash, checksum);
        mp.addRecord(RecordType.String, RecordTag.SourcePath,
                ymlPath.relativePath(event.basePath));
        logDiagnostic(format!"YAML %s : %s"(ymlPath.relativePath(event.basePath), checksum));

        auto spec = new Spec(File(ymlPath, "r"));
        spec.parse();

        string sourceID;
        string architecture;
        string[] licenses;
        string summary;
        Provider[] providers;
        Dependency[] dependencies;
        Dependency[] buildDependencies;
        uint64_t relno = 0;
        string versionID;

        foreach (payload; payloads)
        {
            auto meta = cast(MetaPayload) payload;
            foreach (record; meta)
            {
                switch (record.tag)
                {
                case RecordTag.License:
                    licenses ~= record.get!string;
                    break;
                case RecordTag.Depends:
                    dependencies ~= record.get!Dependency;
                    break;
                case RecordTag.Provides:
                    providers ~= record.get!Provider;
                    break;
                case RecordTag.Name:
                    providers ~= Provider(record.get!string,
                            ProviderType.PackageName);
                    break;
                case RecordTag.Release:
                    relno = record.get!uint64_t;
                    break;
                case RecordTag.Version:
                    versionID = record.get!string;
                    break;
                case RecordTag.SourceID:
                    sourceID = record.get!string;
                    break;
                case RecordTag.BuildDepends:
                    buildDependencies ~= record.get!Dependency;
                    break;
                case RecordTag.Architecture:
                    architecture = record.get!string;
                    break;
                default:
                    /* Ignore */
                    break;
                }
            }
        }

        mp.addRecord(RecordType.String, RecordTag.SourceID, sourceID);
        mp.addRecord(RecordType.String, RecordTag.Architecture, architecture);
        mp.addRecord(RecordType.String, RecordTag.Name, sourceID);
        mp.addRecord(RecordType.String, RecordTag.Summary, spec.rootPackage.summary);
        mp.addRecord(RecordType.String, RecordTag.Description, spec.rootPackage.description);
        mp.addRecord(RecordType.String, RecordTag.Homepage, spec.source.homepage);

        /* Licenses */
        licenses.sort();
        foreach (l; licenses.uniq)
        {
            mp.addRecord(RecordType.String, RecordTag.License, l);
        }

        /* Build deps */
        buildDependencies.sort();
        foreach (b; buildDependencies.uniq)
        {
            mp.addRecord(RecordType.Dependency, RecordTag.BuildDepends, b);
        }

        /* Run deps */
        dependencies.sort();
        foreach (d; dependencies.uniq)
        {
            mp.addRecord(RecordType.Dependency, RecordTag.Depends, d);
        }

        /* Providers */
        providers.sort();
        foreach (p; providers.uniq)
        {
            mp.addRecord(RecordType.Provider, RecordTag.Provides, p);
        }

        /* Relno/version */
        mp.addRecord(RecordType.String, RecordTag.Version, versionID);
        mp.addRecord(RecordType.Uint64, RecordTag.Release, relno);

        metaDB.install(mp);
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

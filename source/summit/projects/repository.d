/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.projects.repository
 *
 * Repository management
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.projects.repository;

import moss.client.metadb;
import moss.core.util : computeSHA256;
import moss.format.binary.payload.meta;
import moss.format.binary.reader;
import moss.format.source.spec;
import moss.service.context;
import std.algorithm : map, sort, uniq;
import std.array : array;
import std.conv : to;
import std.file : dirEntries, exists, mkdirRecurse, rmdirRecurse, SpanMode;
import std.path : buildPath, dirName, relativePath;
import summit.projects.project;
import summit.models.repository;
import vibe.core.channel;
import vibe.core.process;
import std.parallelism : task;
import vibe.d;

/**
 * An explicitly managed repository
 *
 * Note in the design for Summit we opted for monorepos and minimal projects.
 * We don't intend to support thousands of parallel DB connections, and the community
 * project handles all the "personal use" cases quite nicely.
 *
 * Thus the decision to rely on MetaDB/LMDB is ok at this minimalist scale.
 *
 */
public final class ManagedRepository
{
    @disable this();

    /**
     * Construct a new ManagedRepository from an input model
     *
     * Params:
     *      context = global context
     *      parent = Parent project
     *      model = Database model
     */
    this(ServiceContext context, ManagedProject parent, Repository model) @safe
    {
        this.context = context;
        this.parent = parent;

        this._model = model;
        /* ID field never changes */
        this._dbPath = parent.dbPath.buildPath(to!string(model.id));

        this._workPath = context.cachePath.buildPath("repository", to!string(model.id), "work");
        this._clonePath = context.cachePath.buildPath("repository", to!string(model.id), "clone");

        /* We need read/write pls */
        this._db = new MetaDB(dbPath, true);
    }

    /**
     * Returns: Parent project
     */
    pure @property ManagedProject project() @safe @nogc nothrow
    {
        return parent;
    }

    /**
     * Returns: database connection
     */
    pure @property MetaDB db() @safe @nogc nothrow
    {
        return _db;
    }

    /**
     * Returns: Underlying database model
     */
    pure @property Repository model() @safe @nogc nothrow
    {
        return _model;
    }

    /**
     * Returns: database path specific to this repository
     */
    pure @property string dbPath() @safe @nogc nothrow const
    {
        return _dbPath;
    }

    /** 
     * Returns: git clone path
     */
    pure @property string clonePath() @safe @nogc nothrow const
    {
        return _clonePath;
    }

    /**
     * Returns: work indexing path
     */
    pure @property string workPath() @safe @nogc nothrow const
    {
        return _workPath;
    }

    /**
     * Close underlying resources
     */
    void close() @safe
    {
        _db.close();
    }

    /**
     * Attempt to connect with underlying storage
     *
     * Returns: nullable error
     */
    auto connect() @safe
    {
        auto parentDbPath = dbPath.dirName;
        parentDbPath.mkdirRecurse();

        return _db.connect();
    }

    /**
     * Refresh this repository
     *
     * Returns: true if the repository changed
     */
    bool refresh() @safe
    {
        switch (model.status)
        {
        case RepositoryStatus.Fresh:
            cloneGit();
            break;
        case RepositoryStatus.Idle:
            updateGit();
            break;
        default:
            break;
        }

        /* Let caller know if something changed, reindex if needed */
        auto anythingChanged = checkForChanges();
        if (anythingChanged)
        {
            reindex();
        }
        return anythingChanged;
    }

private:

    /**
     * Clone repository for the first time
     */
    void cloneGit() @safe
    {
        /* We need the *parent* clone directory to exist */
        if (clonePath.exists)
        {
            clonePath.rmdirRecurse();
        }
        clonePath.dirName.mkdirRecurse();

        /* Update the marker for cloning */
        _model.status = RepositoryStatus.Cloning;
        immutable err = context.appDB.update((scope tx) => _model.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        string[] cmd = [
            "git", "clone", "--mirror", "--", model.originURI, clonePath
        ];
        string[string] env;
        auto ret = spawnProcess(cmd, env, Config.none, NativePath(context.cachePath));
        auto statusCode = ret.wait();

        /* Check if we can clone */
        if (statusCode != 0)
        {
            logError(format!"Failed to clone %s: %s"(model, statusCode));
            return;
        }

        /* Now mark us idle - ready for checkouts, etc. */
        _model.status = RepositoryStatus.Fresh;
        immutable errMark = context.appDB.update((scope tx) => _model.save(tx));
        enforceHTTP(errMark.isNull, HTTPStatus.internalServerError, err.message);
    }

    /** 
     * Update an existing clone
     */
    void updateGit() @safe
    {
        enforceHTTP(clonePath.exists, HTTPStatus.internalServerError, "clonePath: Should exist!");

        /* Mark ourselves as updating now */
        _model.status = RepositoryStatus.Updating;
        immutable err = context.appDB.update((scope tx) => _model.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        string[] cmd = ["git", "remote", "update"];
        string[string] env;
        auto ret = spawnProcess(cmd, env, Config.none, NativePath(clonePath));
        auto statusCode = ret.wait();

        if (statusCode != 0)
        {
            logError(format!"Failed to update %s: %s"(model, statusCode));
        }

        _model.status = RepositoryStatus.Idle;
        immutable errMark = context.appDB.update((scope tx) => _model.save(tx));
        enforceHTTP(errMark.isNull, HTTPStatus.internalServerError, err.message);
    }

    /**
     * Check for any changes
     */
    bool checkForChanges() @safe
    {
        immutable oldRef = _model.commitRef;
        enforceHTTP(clonePath.exists, HTTPStatus.internalServerError, "clonePath: Should exist!");

        string[] cmd = ["git", "rev-parse", "HEAD"];
        string[string] env;
        auto ret = execute(cmd, env, Config.none, ulong.max, NativePath(clonePath));
        if (ret.status != 0)
        {
            logError(format!"Failed to check HEAD for %s: %s"(model, ret.status));
            return false;
        }

        /* Store new commitRef */
        _model.commitRef = ret.output.strip;
        immutable err = context.appDB.update((scope tx) => _model.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        if (oldRef != _model.commitRef)
        {
            logDiagnostic(format!"Repository %s HEAD is now at '%s'"(_model.name,
                    _model.commitRef));
            return true;
        }
        return false;
    }

    /**
     * Walk the assets in this repository and reindex!
     */
    void reindex() @safe
    {
        /* Give us somewhere to clone things */
        if (workPath.exists)
        {
            workPath.rmdirRecurse();
        }
        workPath.dirName.mkdirRecurse();

        /* Mark for indexing */
        _model.status = RepositoryStatus.Indexing;
        immutable err = context.appDB.update((scope tx) => _model.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        string[string] env;
        string[] cmd = [
            "git", "clone", "--depth=1", "--", format!"file://%s"(clonePath),
            workPath
        ];
        auto ret = spawnProcess(cmd, env, Config.none, NativePath(context.cachePath));
        auto statusCode = ret.wait();

        if (statusCode != 0)
        {
            logError(format!"Failed to checkout clone %s: %s"(_model, statusCode));
        }

        updateDocumentation();
        updatePackages();

        /* Restore idle marker */
        _model.status = RepositoryStatus.Idle;
        immutable errMark = context.appDB.update((scope tx) => _model.save(tx));
        enforceHTTP(errMark.isNull, HTTPStatus.internalServerError, errMark.message);
    }

    /**
     * Update the associated documentation (README.md)
     */
    void updateDocumentation() @safe
    {
        immutable documentation = workPath.buildPath("README.md");
        if (!documentation.exists)
        {
            return;
        }
        immutable desc = readFileUTF8(NativePath(documentation));
        _model.description = desc;
        immutable err = context.appDB.update((scope tx) => _model.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    /**
     * Lock in coro-friendly fashion around separate thread to update the MetaDB
     */
    void updatePackages() @safe
    {
        Channel!(bool, 1) notifyChannel = createChannel!(bool, 1);
        bool unusedRet;

        /* spawn the worker */
        logDiagnostic("Begin updatePackagesThreaded");
        auto t = task!updatePackagesThreaded(notifyChannel, _db, workPath,
                model.commitRef, model.originURI);
        t.executeInNewThread();

        /* Await closure from recipient */
        while (!notifyChannel.empty)
        {
            notifyChannel.tryConsumeOne(unusedRet);
        }
        logDiagnostic("Returned to updatePackages");
    }

    /**
     * Process all of the packages we encounter
     */
    static void updatePackagesThreaded(Channel!(bool, 1) notifyChannel,
            MetaDB db, string workPath, string commitRef, string originURI) @safe
    {
        /* Let run scope know we're done */
        scope (exit)
        {
            logDiagnostic("Exit updatePackagesThreaded");
            notifyChannel.put(true);
            notifyChannel.close();
        }
        logDiagnostic("Enter updatePackagesThreaded");

        auto manifestEntries = () @trusted {
            return workPath.dirEntries("manifest.*.bin", SpanMode.depth, false)
                .map!((m) => m.name).array;
        }();

        db.removeAll();

        foreach (entry; manifestEntries)
        {
            installManifest(db, entry, workPath, commitRef, originURI);
        }
    }

    /**
     * Install manifest into the MetaDB
     */
    static void installManifest(MetaDB metaDB, string manifestPath,
            string workPath, string commitRef, string originURI) @trusted
    {
        scope rdr = new Reader(File(manifestPath, "rb"));
        auto payloads = rdr.payloads!MetaPayload;
        if (payloads.empty)
        {
            logWarn(format!"Missing payloads in manifest %s"(manifestPath));
            return;
        }

        MetaPayload mp = new MetaPayload();
        mp.addRecord(RecordType.String, RecordTag.SourceRef, commitRef);
        mp.addRecord(RecordType.String, RecordTag.SourceURI, originURI);
        immutable ymlPath = manifestPath.dirName.buildPath("stone.yml");
        immutable checksum = computeSHA256(manifestPath, true);
        mp.addRecord(RecordType.String, RecordTag.PackageHash, checksum);
        mp.addRecord(RecordType.String, RecordTag.SourcePath, ymlPath.relativePath(workPath));

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

    ManagedProject parent;
    ServiceContext context;
    MetaDB _db;
    Repository _model;
    string _dbPath;
    string _clonePath;
    string _workPath;
}

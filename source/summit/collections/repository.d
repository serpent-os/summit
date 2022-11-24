/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.collections.repository
 *
 * Repository management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.collections.repository;

import moss.client.metadb;
import std.conv : to;
import std.path : buildPath, dirName;
import summit.collections.collection;
import summit.context;
import summit.models.repository;
import std.file : mkdirRecurse, rmdirRecurse, exists;
import vibe.d;
import vibe.core.process;

/**
 * An explicitly managed repository
 *
 * Note in the design for Summit we opted for monorepos and minimal collections.
 * We don't intend to support thousands of parallel DB connections, and the community
 * collection handles all the "personal use" cases quite nicely.
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
     *      parent = Parent collection
     *      model = Database model
     */
    this(SummitContext context, ManagedCollection parent, Repository model) @safe
    {
        this.context = context;

        this._model = model;
        /* ID field never changes */
        this._dbPath = parent.dbPath.buildPath(to!string(model.id));

        this._workPath = context.cachePath.buildPath("repository", to!string(model.id), "work");
        this._clonePath = context.cachePath.buildPath("repository", to!string(model.id), "clone");

        /* We need read/write pls */
        this._db = new MetaDB(dbPath, true);
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
     */
    void refresh() @safe
    {
        if (model.status != RepositoryStatus.Idle)
        {
            logDiagnostic(format!"%s: Non idle repository"(model.name));
            return;
        }
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

    SummitContext context;
    MetaDB _db;
    Repository _model;
    string _dbPath;
    string _clonePath;
    string _workPath;
}

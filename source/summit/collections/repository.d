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
import std.file : mkdirRecurse;

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

private:

    SummitContext context;
    MetaDB _db;
    Repository _model;
    string _dbPath;
    string _clonePath;
    string _workPath;
}

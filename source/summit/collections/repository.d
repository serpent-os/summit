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
import std.path : buildPath;
import summit.collections.collection;
import summit.context;
import summit.models.repository;

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
     * Close underlying resources
     */
    void close() @safe
    {
        _db.close();
    }

private:

    SummitContext context;
    MetaDB _db;
    Repository _model;
    string _dbPath;
}

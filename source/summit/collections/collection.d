/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.context
 *
 * Collection management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.collections.collection;

import moss.db.keyvalue;
import std.conv : to;
import std.path : buildPath;
import summit.collections.repository;
import summit.context;
import summit.models.collection;
import summit.models.repository;

/**
 * A collection explicitly managed by Summit
 */
public final class ManagedCollection
{
    @disable this();

    /** 
     * Construct a new ManagedCollection
     *
     * Params:
     *      context = global context
     *      model = Database model
     */
    this(SummitContext context, PackageCollection model) @safe
    {
        this.context = context;
        this._model = model;
        /* The ID field never changes */
        this._dbPath = context.dbPath.buildPath("collections", to!string(model.id));
    }

    /**
     * Returns: Underlying DB model
     */
    pure @property PackageCollection model() @safe @nogc nothrow
    {
        return _model;
    }

    /**
     * Returns: This collection's managed repositories
     */
    pure @property auto repositories() @safe @nogc nothrow
    {
        return managed;
    }

    /**
     * Close all underlying resources
     */
    void close() @safe
    {
        foreach (m; managed)
        {
            m.close();
        }
    }

    /**
     * Returns: dbPath specific to this collection
     */
    pure @property string dbPath() @safe @nogc nothrow const
    {
        return _dbPath;
    }

package:

    /**
     * Connect via the given transaction to initialise this collection
     */
    DatabaseResult connect(in Transaction tx) @safe
    {
        foreach (repo; tx.list!Repository)
        {
            auto r = new ManagedRepository(context, this, repo);
            managed ~= r;
        }
        return NoDatabaseError;
    }

private:

    SummitContext context;
    PackageCollection _model;
    ManagedRepository[] managed;
    string _dbPath;
}

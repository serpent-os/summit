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
    }

    /**
     * Returns: Underlying DB model
     */
    pure @property PackageCollection model() @safe @nogc nothrow
    {
        return _model;
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
        }
        return NoDatabaseError;
    }

private:

    SummitContext context;
    PackageCollection _model;
}

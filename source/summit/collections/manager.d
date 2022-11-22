/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.context
 *
 * The manager manager.
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.collections.manager;

import summit.context;
import summit.models.collection;
import moss.db.keyvalue;
import summit.collections.collection;

/**
 * The CollectionManager helps us to control the correlation between
 * the database model of collections and *usable* objects from within
 * the context of the main thread.
 */
public final class CollectionManager
{
    @disable this();

    /**
     * Construct a new CollectionManager for the given context
     */
    this(SummitContext context) @safe
    {
        this.context = context;
    }

    /**
     * Connect with the underlying database and initialise the managed
     * instances
     *
     * Returns: Nullable error
     */
    DatabaseResult connect() @safe
    {
        DatabaseResult colLoader(in Transaction tx) @safe
        {
            foreach (model; tx.list!PackageCollection)
            {
                auto c = new ManagedCollection(context, model);
                immutable err = c.connect(tx);
                if (!err.isNull)
                {
                    return err;
                }
                managed ~= c;
            }
            return NoDatabaseError;
        }

        return context.appDB.view(&colLoader);
    }

    /**
     * Returns: all managed collections
     */
    pure auto @property collections() @safe @nogc nothrow
    {
        return managed;
    }

private:

    SummitContext context;
    ManagedCollection[] managed;
}

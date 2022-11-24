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
import moss.core.errors;
import vibe.d : runTask;

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
    pure @property auto repositories() @safe nothrow
    {
        return managed.values;
    }

    /** 
     * Returns: Repository within this collection
     *
     * Params:
     *      slug = Unique identifier
     */
    pure @property auto bySlug(in string slug) @safe nothrow
    {
        auto repo = (slug in managed);
        return repo ? *repo : null;
    }

    /**
     * Close all underlying resources
     */
    void close() @safe
    {
        foreach (k, r; managed)
        {
            r.close();
        }
    }

    /**
     * Returns: dbPath specific to this collection
     */
    pure @property string dbPath() @safe @nogc nothrow const
    {
        return _dbPath;
    }

    /**
     * Add a repository to this collection
     *
     * Params:
     *      model = Input model
     * Returns: Nullable database error
     */
    DatabaseResult addRepository(Repository model) @safe
    {
        /* Ensure we bypass DB for quick repo lookup */
        auto lookup = (model.name in managed);
        if (lookup !is null)
        {
            return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketExists,
                    "Repository already exists"));
        }

        /* Reset basic fields */
        model.id = 0;
        model.status = RepositoryStatus.Fresh;
        model.commitRef = "";

        /* Link the collection */
        model.collection = this._model.id;

        /* Try to store the model */
        immutable err = context.appDB.update((scope tx) => model.save(tx));
        if (!err.isNull)
        {
            return err;
        }

        /* Get it managed */
        auto managedRepository = new ManagedRepository(context, this, model);
        return managedRepository.connect.match!((Success _) {
            managed[model.name] = managedRepository;
            runTask({ managedRepository.refresh(); });
            return NoDatabaseError;
        }, (Failure f) => DatabaseResult(DatabaseError(cast(DatabaseErrorCode) f.specifier,
                f.message)));
    }

package:

    /**
     * Connect via the given transaction to initialise this collection
     *
     * Params:
     *      tx = read-only transaction
     * Returns: nullable database error
     */
    DatabaseResult connect(in Transaction tx) @safe
    {
        foreach (repo; tx.list!Repository)
        {
            auto r = new ManagedRepository(context, this, repo);
            DatabaseResult err = r.connect.match!((Failure f) => DatabaseResult(
                    DatabaseError(cast(DatabaseErrorCode) f.specifier, f.message)),
                    (Success s) => NoDatabaseError);
            if (!err.isNull)
            {
                return err;
            }
            managed[repo.name] = r;

        }
        return NoDatabaseError;
    }

    /**
     * Attempt to update all repositories
     * At this point, go wide.
     */
    void refresh() @safe
    {
        foreach (slug, repo; managed)
        {
            runTask({ repo.refresh(); });
        }
    }

private:

    SummitContext context;
    PackageCollection _model;
    ManagedRepository[string] managed;
    string _dbPath;
}

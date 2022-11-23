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

import vibe.core.core : setTimer;
import vibe.d;

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
                managed[model.slug] = c;
            }
            return NoDatabaseError;
        }

        /* Set up the model in memory */
        immutable err = context.appDB.view(&colLoader);
        if (!err.isNull)
        {
            return err;
        }

        /* Start interval timer */
        running = true;
        () @trusted { curTimer = setTimer(30.seconds, &updateCollections); }();
        return NoDatabaseError;
    }

    /**
     * Close all underlying resources
     */
    void close() @safe
    {
        running = false;
        curTimer.stop();

        foreach (k, c; managed)
        {
            c.close();
        }
    }

    /**
     * Returns: all managed collections
     */
    pure auto @property collections() @safe nothrow
    {
        return managed.values;
    }

    /**
     * Returns: a collection by slug
     *
     * Params:
     *      slug = Slug identifier
     */
    pure auto bySlug(in string slug) @safe nothrow
    {
        auto result = (slug in managed);
        return result ? *result : null;
    }

private:

    /**
     * Iterate all collections and request they update themselves, and obviously, their repos
     */
    void updateCollections() @safe
    {
        auto now = Clock.currTime();
        logInfo(format!"Updating collections at %s"(now));
        scope (exit)
        {
            runTask({
                /* Reinstall the timer */
                () @trusted {
                    curTimer = setTimer(30.seconds, &updateCollections);
                }();
            });
        }

        /* Update each collection */
        foreach (slug, col; managed)
        {
            logDiagnostic(format!"Requesting update check for %s"(slug));
            col.refresh();
        }
    }

    SummitContext context;
    ManagedCollection[string] managed;
    bool running;
    Timer curTimer;
}

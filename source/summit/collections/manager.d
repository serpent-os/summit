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

private:

    SummitContext context;
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.context
 *
 * Contextual storage - DBs, etc.
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.collections.manager;

import summit.context;

/**
 * The CollectionsManager helps us to control the correlation between
 * the database model of collections and *usable* objects from within
 * the context of the main thread.
 */
public final class CollectionsManager
{
    @disable this();

    /**
     * Construct a new CollectionsManager for the given context
     */
    this(SummitContext context) @safe
    {

    }

private:

    SummitContext context;
}

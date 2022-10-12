/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.collection
 *
 * Model for collection storage
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.models.collection;

import moss.db.keyvalue.orm;
public import std.stdint : uint64_t;

/**
 * Unique assignment to survive renames, etc.
 */
public alias CollectionID = uint64_t;

/**
 * Collection is our encapsulation unit for a repository
 */
public @Model struct Collection
{
    /**
     * Unique id for the collection
     */
    CollectionID id;

    /**
     * Unique name for the collection
     */
    @Indexed string name;
}

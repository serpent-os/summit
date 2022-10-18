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
public alias PackageCollectionID = uint64_t;

/**
 * Collection is our encapsulation unit for a repository
 */
public @Model struct PackageCollection
{
    /**
     * Unique id for the collection
     */
    @PrimaryKey @AutoIncrement PackageCollectionID id;

    /**
     * Unique name for the collection
     */
    @Indexed string name;

    /**
     * Unique slug ID (i.e. serpent-os)
     */
    string slug;

    /**
     * Brief description of the collection
     */
    string summary;

    /** 
     * Release tracking
     */
    string vscURI;
}

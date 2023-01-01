/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.collection
 *
 * Model for collection storage
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
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
     * Display name for the collection
     */
    string name;

    /**
     * Unique slug ID (i.e. serpent-os)
     */
    @Indexed string slug;

    /**
     * Brief description of the collection
     */
    string summary;

    /** 
     * Release tracking
     */
    string vscURI;
}

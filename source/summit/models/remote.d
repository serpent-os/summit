/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.remote
 *
 * Model for moss remote storage
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.models.remote;

import moss.db.keyvalue.orm;
public import std.stdint : uint64_t;
public import summit.models.profile : ProfileID;

/**
 * Unique assignment to survive renames, etc.
 */
public alias RemoteID = uint64_t;

/**
 * Project is our encapsulation unit for a bunch of repos
 */
public @Model struct Remote
{
    /**
     * Unique id for the remote
     */
    @PrimaryKey @AutoIncrement RemoteID id;

    /**
     * Display name for the remote
     */
    string name;

    /**
     * Priority within build roots
     */
    uint priority;

    /**
     * Where is the index found?
     */
    string indexURI;

    /**
     * What profile does this belong to?
     */
    ProfileID profileID;
}

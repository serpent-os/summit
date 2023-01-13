/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.project
 *
 * Model for project storage
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.models.project;

import moss.db.keyvalue.orm;
public import std.stdint : uint64_t;

/**
 * Unique assignment to survive renames, etc.
 */
public alias ProjectID = uint64_t;

/**
 * Project is our encapsulation unit for a bunch of repos
 */
public @Model struct Project
{
    /**
     * Unique id for the project
     */
    @PrimaryKey @AutoIncrement ProjectID id;

    /**
     * Display name for the project
     */
    string name;

    /**
     * Unique slug ID (i.e. serpent-os)
     */
    @Indexed string slug;

    /**
     * Brief description of the project
     */
    string summary;
}

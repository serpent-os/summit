/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.profile
 *
 * Model for build profiles
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.models.profile;

import moss.db.keyvalue.orm;
public import std.stdint : uint64_t;
public import summit.models.project : ProjectID;
public import summit.models.remote : RemoteID;

/**
 * Unique assignment to survive renames, etc.
 */
public alias ProfileID = uint64_t;

/**
 * Encapsulation of Build profiles
 */
public @Model struct Profile
{
    /**
     * Unique id for the profile
     */
    @PrimaryKey @AutoIncrement ProfileID id;

    /**
     * Display name for the project
     */
    string name;

    /**
     * Architecture string
     */
    string arch;

    /**
     * Where can we expect to see this published?
     */
    string volatileIndexURI;

    /**
     * What project does this belong to?
     */
    ProjectID projectID;
}

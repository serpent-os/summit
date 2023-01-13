/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.repository
 *
 * Model for project storage
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.models.repository;

import moss.db.keyvalue.orm;

public import summit.models.project : ProjectID;
public import std.stdint : uint64_t;

public alias RepositoryID = uint64_t;

/**
 * Used to signify what a repository is doing, and to identify
 * candidates
 */
public enum RepositoryStatus
{
    /**
     * Never cloned before
     */
    Fresh = 0,

    /**
     * Updating git ref
     */
    Updating,

    /**
     * Cloning for the first time
     */
    Cloning,

    /**
     * Indexing for updates
     */
    Indexing,

    /**
     * Doing nothing (most repos)
     */
    Idle,
}

/**
 * Project is our encapsulation unit for a repository
 */
public @Model struct Repository
{
    /**
     * Unique identifier for the repository
     */
    @AutoIncrement @PrimaryKey RepositoryID id;

    /**
     * Name for this repository
     */
    @Indexed string name;

    /**
     * Summary for the primary repository purpose
     */
    string summary;

    /**
     * Set to the markdown description in the repository (README.md)
     */
    string description;

    /**
     * The commit the last time we scanned
     */
    string commitRef;

    /**
     * Where can we find the upstream sources?
     */
    string originURI;

    /**
     * Which project do we belong to?
     */
    ProjectID project;

    /**
     * Current status. All start out fresh
     */
    RepositoryStatus status = RepositoryStatus.Fresh;
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.repository
 *
 * Model for collection storage
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.models.repository;

import moss.db.keyvalue.orm;

public import summit.models.collection : CollectionID;

/**
 * Collection is our encapsulation unit for a repository
 */
public @Model struct Repository
{
    /**
     * Unique id for the collection
     */
    @PrimaryKey string id;

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
     * Which collection do we belong to?
     */
    CollectionID collection;
}

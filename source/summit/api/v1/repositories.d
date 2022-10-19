/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.repositories
 *
 * V1 Summit Repositories API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.repositories;

public import summit.api.v1.interfaces;
import vibe.d;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.models.collection;
import summit.models.repository;

/**
 * Implements the CollectionsAPIv1
 */
public final class RepositoriesService : RepositoriesAPIv1
{
    @disable this();

    /**
     * Construct new CollectionsService
     */
    this(Database appDB) @safe
    {
        this.appDB = appDB;
    }

    /**
     * Enumerate all of the repos
     *
     * Params:
     *      _collection: Collection slug
     *
     * Returns: ListItem[] of known repos
     */
    override ListItem[] enumerate(string _collection) @safe
    {
        return null;
    }

private:
    Database appDB;
}

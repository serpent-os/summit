/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.recipes
 *
 * V1 Summit Recipes API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.recipes;

public import summit.api.v1.interfaces;
import vibe.d;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.client.metadb;
import std.array : array;
import std.algorithm : map, sort;

/**
 * Implements the RecipesAPIv1
 */
public final class RecipesService : RecipesAPIv1
{
    @disable this();

    /**
     * Construct new RecipesService
     */
    this(Database appDB) @safe
    {
        this.appDB = appDB;
    }

    /**
     * Enumerate all of the recipes
     *
     * Params:
     *      _collection: Collection slug
     *      _repo: Repo slug
     *
     * Returns: ListItem[] of known repos
     */
    override Paginator!ListItem enumerate(string _collection, string _repo, ulong pageNumber = 0) @safe
    {
        ListItem[] ret;
        return Paginator!ListItem(ret, pageNumber);
    }

private:
    Database appDB;
}

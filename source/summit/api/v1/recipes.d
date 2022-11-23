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
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import std.algorithm : map, sort;
import std.array : array;
import summit.context;
import vibe.d;

/**
 * Implements the RecipesAPIv1
 */
public final class RecipesService : RecipesAPIv1
{
    @disable this();

    /**
     * Construct new RecipesService
     *
     * Params:
     *      context = global context
     */
    this(SummitContext context) @safe
    {
        this.context = context;
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
    SummitContext context;
}

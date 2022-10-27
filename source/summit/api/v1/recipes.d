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
    this(MetaDB metaDB, Database appDB) @safe
    {
        this.appDB = appDB;
        this.metaDB = metaDB;
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
        auto items = metaDB.list.map!((m) {
            ListItem i;
            i.id = m.pkgID;
            i.context = ListContext.Recipes;
            i.title = format!"%s - %s-%s"(m.sourceID, m.versionIdentifier, m.sourceRelease);
            i.slug = format!"/~/%s/%s/%s"(_collection, _repo, m.sourceID);
            i.subtitle = m.summary;
            return i;
        });
        ret = () @trusted { return items.array; }();
        ret.sort!((a, b) => a.title < b.title);
        return Paginator!ListItem(ret, pageNumber);
    }

private:
    Database appDB;
    MetaDB metaDB;
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.collections
 *
 * V1 Summit Collections API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.collections;

public import summit.api.v1.interfaces;
import vibe.d;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.models.collection;
import std.algorithm : map;
import std.array : array;

/**
 * Implements the CollectionsAPIv1
 */
public final class CollectionsService : CollectionsAPIv1
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
     * Enumerate all of the collections
     *
     * Returns: ListItem[] of known collections
     */
    override ListItem[] enumerate() @safe
    {
        ListItem[] renderable;
        appDB.view((in tx) @safe {
            auto items = tx.list!PackageCollection
                .map!((c) {
                    ListItem ret;
                    ret.context = ListContext.Collections;
                    ret.id = to!string(c.id);
                    ret.title = c.name;
                    ret.subtitle = "undescribed";
                    return ret;
                });
            renderable = () @trusted { return items.array; }();
            return NoDatabaseError;
        });
        return renderable;
    }

    /**
     * Create a new collection
     *
     * Params:
     *      request = Creation request
     */
    override void create(CreateCollection request) @safe
    {
        logInfo(format!"Constructing new collection: %s"(request));
        auto c = PackageCollection();
        c.name = request.name;
        c.vscURI = request.releaseURI;
        immutable err = appDB.update((scope tx) => c.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.badRequest, err.message);
    }

private:
    Database appDB;
}

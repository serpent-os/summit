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
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import std.algorithm : map;
import std.array : array;
import summit.context;
import summit.models.collection;
import vibe.d;

/**
 * Implements the CollectionsAPIv1
 */
public final class CollectionsService : CollectionsAPIv1
{
    @disable this();

    /**
     * Construct new CollectionsService
     *
     * Params:
     *      context = global context
     */
    this(SummitContext context) @safe
    {
        this.context = context;
    }

    /**
     * Enumerate all of the collections
     *
     * Returns: ListItem[] of known collections
     */
    override ListItem[] enumerate() @safe
    {
        ListItem[] renderable;
        context.appDB.view((in tx) @safe {
            auto items = tx.list!PackageCollection
                .map!((c) {
                    ListItem ret;
                    ret.context = ListContext.Collections;
                    ret.id = to!string(c.id);
                    ret.title = c.name;
                    ret.subtitle = c.summary;
                    ret.slug = format!"/~/%s"(c.slug);
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
        c.slug = request.slug;
        c.vscURI = request.releaseURI;
        c.summary = request.summary;
        immutable err = context.appDB.update((scope tx) => c.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.badRequest, err.message);
    }

private:
    SummitContext context;
}

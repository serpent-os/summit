/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.collections
 *
 * V1 Summit Collections API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.collections;

public import summit.api.v1.interfaces;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import std.algorithm : map;
import std.array : array;
import summit.collections;
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
     *      collectionManager = Collection management
     */
    this(ServiceContext context, CollectionManager collectionManager) @safe
    {
        this.context = context;
        this.collectionManager = collectionManager;
    }

    /**
     * Enumerate all of the collections
     *
     * Returns: ListItem[] of known collections
     */
    override ListItem[] enumerate() @safe
    {
        auto ret = collectionManager.collections.map!((c) {
            ListItem ret;
            ret.context = ListContext.Collections;
            ret.id = to!string(c.model.id);
            ret.title = c.model.name;
            ret.subtitle = c.model.summary;
            ret.slug = format!"/~/%s"(c.model.slug);
            return ret;
        });
        return () @trusted { return ret.array; }();
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
        immutable err = collectionManager.addCollection(c);
        enforceHTTP(err.isNull, HTTPStatus.badRequest, err.message);
    }

private:
    ServiceContext context;
    CollectionManager collectionManager;
}

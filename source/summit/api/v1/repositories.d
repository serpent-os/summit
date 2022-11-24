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
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import std.algorithm : filter, map;
import std.array : array;
import summit.collections;
import summit.context;
import summit.models.collection;
import summit.models.repository;
import vibe.d;

/**
 * Implements the CollectionsAPIv1
 */
public final class RepositoriesService : RepositoriesAPIv1
{
    @disable this();

    /**
     * Construct new RepositoriesService
     *
     * Params:
     *      context = global context
     */
    this(SummitContext context, CollectionManager collectionManager) @safe
    {
        this.context = context;
        this.collectionManager = collectionManager;
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
        ManagedCollection collection = collectionManager.bySlug(_collection);
        enforceHTTP(collectionManager !is null, HTTPStatus.notFound);

        auto ret = collection.repositories.map!((r) {
            ListItem item;
            item.id = to!string(r.model.id);
            item.title = r.model.name;
            item.slug = format!"/~/%s/%s"(_collection, r.model.name);
            item.subtitle = r.model.summary;
            item.context = ListContext.Repositories;
            return item;
        });
        return () @trusted { return ret.array; }();
    }

    /**
     * Create new repo within collection
     *
     * Params:
     *      _collection: Collection slug
     *      request: JSON Request
     */
    override void create(string _collection, CreateRepository request) @safe
    {
        PackageCollection collection;
        immutable colErr = context.appDB.view((in tx) => collection.load!"slug"(tx, _collection));
        enforceHTTP(colErr.isNull, HTTPStatus.notFound, colErr.message);
        Repository repo;
        repo.name = request.id;
        repo.collection = collection.id;
        repo.description = "not yet loaded";
        repo.summary = request.summary;
        repo.originURI = request.originURI;
        immutable err = context.appDB.update((scope tx) => repo.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.forbidden, err.message);
        logInfo(format!"Create at %s: %s"(_collection, request));
    }

private:
    SummitContext context;
    CollectionManager collectionManager;
}

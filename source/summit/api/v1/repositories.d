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
import std.algorithm : filter, map;
import std.array : array;

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
        ListItem[] ret;
        PackageCollection collection;
        immutable err = appDB.view((in tx) => collection.load!"slug"(tx, _collection));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);

        appDB.view((in tx) @safe {
            auto items = tx.list!Repository
                .filter!((r) => r.collection == collection.id)
                .map!((i) {
                    ListItem item;
                    item.id = to!string(i.id);
                    item.title = i.name;
                    item.slug = format!"/~/%s/%s"(_collection, i.name);
                    item.subtitle = i.summary;
                    item.context = ListContext.Repositories;
                    return item;
                });
            ret = () @trusted { return items.array; }();
            return NoDatabaseError;
        });
        return ret;
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
        immutable colErr = appDB.view((in tx) => collection.load!"slug"(tx, _collection));
        enforceHTTP(colErr.isNull, HTTPStatus.notFound, colErr.message);
        Repository repo;
        repo.name = request.id;
        repo.collection = collection.id;
        repo.description = "not yet loaded";
        repo.summary = request.summary;
        repo.originURI = request.originURI;
        immutable err = appDB.update((scope tx) => repo.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.forbidden, err.message);
        logInfo(format!"Create at %s: %s"(_collection, request));
    }

private:
    Database appDB;
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.collections
 *
 * Collections Web API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.collections;

import vibe.d;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.models.collection;
import summit.models.repository;
import moss.client.metadb;

/**
 * Root entry into our web service
 */
@path("/~")
public final class CollectionsWeb
{
    /**
     * Join CollectionsWeb into the router
     *
     * Params:
     *      appDB = Application database
     *      router = Web root for the application
     */
    @noRoute void configure(Database appDB, MetaDB metaDB, URLRouter router) @safe
    {
        this.appDB = appDB;
        this.metaDB = metaDB;
        registerWebInterface(router, this);
    }

    /**
     * Collections index
     */
    void index() @safe
    {
        render!"collections/index.dt";
    }

    /**
     * View an individual collection
     *
     * Params:
     *      _slug = Specific slug ID (i.e. collection short name)
     */
    @path("/:slug") @method(HTTPMethod.GET)
    void view(string _slug)
    {
        PackageCollection collection;
        immutable err = appDB.view((in tx) => collection.load!"slug"(tx, _slug));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
        render!("collections/view.dt", collection);
    }

    /**
     * View a repo within a collection
     *
     * Params:
     *      _slug = Collection ID
     *      _repo = Repo ID
     */
    @path("/:slug/:repo") @method(HTTPMethod.GET)
    void viewRepo(string _slug, string _repo)
    {
        PackageCollection collection;
        Repository repo;
        /* TODO: Exist outside global constraints */
        immutable err = appDB.view((in tx) @safe {
            auto eCol = collection.load!"slug"(tx, _slug);
            if (!eCol.isNull)
            {
                return eCol;
            }

            return repo.load!"name"(tx, _repo);
        });
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
        render!("collections/repo.dt", collection, repo);
    }

    @path("/:slug/:repo/:recipeID") @method(HTTPMethod.GET)
    void viewRecipe(string _slug, string _repo, string _recipeID) @safe
    {
        PackageCollection collection;
        Repository repo;
        /* TODO: Exist outside global constraints */
        immutable err = appDB.view((in tx) @safe {
            auto eCol = collection.load!"slug"(tx, _slug);
            if (!eCol.isNull)
            {
                return eCol;
            }

            return repo.load!"name"(tx, _repo);
        });
        auto id = metaDB.byProvider(ProviderType.PackageName, _recipeID);
        enforceHTTP(id.length > 0, HTTPStatus.notFound);
        auto recipe = metaDB.byID(id[0]);
        render!("collections/recipe.dt", collection, repo, recipe);
    }

private:

    Database appDB;
    MetaDB metaDB;
}

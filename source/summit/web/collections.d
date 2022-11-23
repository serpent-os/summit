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

import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import summit.context;
import summit.models.collection;
import summit.models.repository;
import vibe.d;

/**
 * Root entry into our web service
 */
@path("/~")
public final class CollectionsWeb
{
    @disable this();

    /**
     * Construct a new CollectionsWeb
     *
     * Params:
     *      context = global context
     */
    this(SummitContext context) @safe
    {
        this.context = context;
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
        immutable err = context.appDB.view((in tx) => collection.load!"slug"(tx, _slug));
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
        immutable err = context.appDB.view((in tx) @safe {
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
        throw new HTTPStatusException(HTTPStatus.notImplemented);
    }

private:

    SummitContext context;
}

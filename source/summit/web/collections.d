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

import moss.deps.registry;
import std.range : empty, front;
import summit.collections;
import summit.context;
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
    this(SummitContext context, CollectionManager collectionManager) @safe
    {
        this.context = context;
        this.collectionManager = collectionManager;
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
        auto collection = collectionManager.bySlug(_slug);
        enforceHTTP(collection !is null, HTTPStatus.notFound);
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
        auto collection = collectionManager.bySlug(_slug);
        enforceHTTP(collection !is null, HTTPStatus.notFound);
        auto repository = collection.bySlug(_repo);
        enforceHTTP(repository !is null, HTTPStatus.notFound);
        render!("collections/repo.dt", collection, repository);
    }

    /** 
     * View a recipe within a specific collection's repository
     *
     * Params:
     *      _slug = Collection ID
     *      _repo = Repository ID
     *      _recipeID = Recipe ID
     */
    @path("/:slug/:repo/:recipeID") @method(HTTPMethod.GET)
    void viewRecipe(string _slug, string _repo, string _recipeID) @safe
    {
        auto collection = collectionManager.bySlug(_slug);
        enforceHTTP(collection !is null, HTTPStatus.notFound);
        auto repository = collection.bySlug(_repo);
        enforceHTTP(repository !is null, HTTPStatus.notFound);

        auto items = repository.db.byProvider(ProviderType.PackageName, _recipeID);
        enforceHTTP(!items.empty, HTTPStatus.notFound);
        auto recipe = repository.db.byID(items.front);
        render!("collections/recipe.dt", collection, repository, recipe);
    }

private:

    SummitContext context;
    CollectionManager collectionManager;
}

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

import summit.context;
import summit.collections;
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
        throw new HTTPStatusException(HTTPStatus.notImplemented);
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
        throw new HTTPStatusException(HTTPStatus.notImplemented);
    }

    @path("/:slug/:repo/:recipeID") @method(HTTPMethod.GET)
    void viewRecipe(string _slug, string _repo, string _recipeID) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented);
    }

private:

    SummitContext context;
    CollectionManager collectionManager;
}

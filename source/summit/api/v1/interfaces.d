/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.interfaces
 *
 * V1 Summit API Interfaces
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.api.v1.interfaces;

public import vibe.d;

import std.range : take, drop;

/**
 * A ListItem can be represented using a specific ListContext
 */
public enum ListContext : string
{
    Collections = "collections",
    Users = "users",
    Groups = "groups",
    Repositories = "repositories",
    Recipes = "recipes",
}

/**
 * We use a Paginator to serve paginated queries over the API
 *
 * Params:
 *      T = Type to paginate
 */
public struct Paginator(T)
{
    /**
     * Each page is locked to 15 display items
     */
    static immutable ulong pageSize = 15;

    /**
     * The subset of items to render
     */
    T[] items;

    /**
     * How many displayable pages?
     */
    ulong numPages;

    /**
     * What page are we on now?
     */
    ulong page;

    /**
     * Should the prev control be rendered?
     */
    bool hasPrevious;

    /**
     * Should the next control be rendered?
     */
    bool hasNext;

    /**
     * Construct a new Paginator
     * pageNumber is indexed from *1*
     */
    this(T[] input, ulong pageNumber) @safe
    {
        this.page = pageNumber;

        /* Minimum 1 page */
        numPages = (input.length / pageSize) + 1;
        page = pageNumber >= numPages ? numPages : pageNumber;
        hasPrevious = page > 0;
        hasNext = page < (numPages - 1);
        items = input.drop(pageNumber * pageSize).take(pageSize);
    }
}

/**
 * Used for marshalling a ListContext item in JS
 */
public struct ListItem
{
    /**
     * What context does this belong in?
     */
    ListContext context;

    /**
     * Unique identifier
     */
    string id;

    /**
     * Full slug URI
     */
    string slug;

    /**
     * The title for the item
     */
    string title;

    /**
     * Subtitle / summary
     */
    string subtitle;

    /**
     * An item may have children too
     */
    ListItem[] children;
}

public struct CreateCollection
{
    string slug;
    string name;
    string summary;
    string releaseURI;
}

public struct CreateRepository
{
    string id;
    string summary;
    string originURI;
}

/**
 * Root API node
 */
@path("/api/v1")
public interface SummitAPIv1
{
    /**
     * Return the actual version identifier
     */
    @path("version") @method(HTTPMethod.GET) pure string versionID() @safe @nogc nothrow const;
}

/**
 * Base API for the Collections
 */
@path("/api/v1/collections")
public interface CollectionsAPIv1
{
    /**
     * Enumerate all items within the collection API
     */
    @path("enumerate") @method(HTTPMethod.GET) ListItem[] enumerate() @safe;

    /**
     * Create a new collection with the given release URI
     */
    @path("create") @method(HTTPMethod.POST) void create(CreateCollection request) @safe;
}

@path("/api/v1/repos")
public interface RepositoriesAPIv1
{
    /**
     * Enumerate all items within the given collection
     */
    @path("enumerate/:collection") @method(HTTPMethod.GET) ListItem[] enumerate(string _collection) @safe;

    /**
     * Create new repo within the given collection
     */
    @path("create/:collection") @method(HTTPMethod.POST) void create(string _collection,
            CreateRepository request) @safe;
}

@path("/api/v1/recipes")
public interface RecipesAPIv1
{
    /**
     * Enumerate all items within the given repository
     */
    @path("enumerate/:collection/:repo") @method(HTTPMethod.GET) Paginator!ListItem enumerate(
            string _collection, string _repo, ulong pageNumber = 0) @safe;
}

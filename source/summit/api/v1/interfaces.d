/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.interfaces
 *
 * V1 Summit API Interfaces
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
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
    Builders = "builders",
    Projects = "projects",
    Users = "users",
    Groups = "groups",
    Repositories = "repositories",
    Recipes = "recipes",
    Endpoints = "endpoints",
    Tasks = "tasks",
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

    /* any special status enums */
    int status = 0;

    /**
     * An item may have children too
     */
    ListItem[] children;
}

/**
 * Request used to create a new project
 */
public struct CreateProject
{
    /**
     * Identity slug
     */
    string slug;

    /**
     * Display name
     */
    string name;

    /**
     * Short one liner description
     */
    string summary;
}

/**
 * Request used to create a new repository
 */
public struct CreateRepository
{
    /**
     * Identity slug
     */
    string id;

    /**
     * One line description
     */
    string summary;

    /**
     * Upstream origin (.git)
     */
    string originURI;
}

/**
 * Request used to attach an endpoint instance
 */
public struct AttachEndpoint
{
    /**
     * Unique identifier within Summit
     */
    string id;

    /**
     * Short description of the purpose/use
     */
    string summary;

    /**
     * Attachment URI
     */
    string instanceURI;

    /**
     * Public key
     */
    string pubkey;

    /**
     * Contact point: Admin name
     */
    string adminName;

    /**
     * Contact point: Admin email
     */
    string adminEmail;
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
 * Base API for the Builders
 */
@path("/api/v1/builders")
public interface BuildersAPIv1
{
    /**
     * Enumerate all items within the builders API
     */
    @path("enumerate") @method(HTTPMethod.GET) ListItem[] enumerate() @safe;

    /**
     * Create a new builder attachment
     */
    @path("create") @method(HTTPMethod.POST) void create(AttachEndpoint request) @safe;
}

/**
 * Base API for the Projects
 */
@path("/api/v1/projects")
public interface ProjectsAPIv1
{
    /**
     * Enumerate all items within the project API
     */
    @path("enumerate") @method(HTTPMethod.GET) ListItem[] enumerate() @safe;

    /**
     * Create a new project with the given release URI
     */
    @path("create") @method(HTTPMethod.POST) void create(CreateProject request) @safe;
}

/**
 * Base API for the Repositories
 */
@path("/api/v1/repos")
public interface RepositoriesAPIv1
{
    /**
     * Enumerate all items within the given project
     */
    @path("enumerate/:project") @method(HTTPMethod.GET) ListItem[] enumerate(string _project) @safe;

    /**
     * Create new repo within the given project
     */
    @path("create/:project") @method(HTTPMethod.POST) void create(string _project,
            CreateRepository request) @safe;
}

/**
 * Base API for the Recipes
 */
@path("/api/v1/recipes")
public interface RecipesAPIv1
{
    /**
     * Enumerate all items within the given repository
     */
    @path("enumerate/:project/:repo") @method(HTTPMethod.GET) Paginator!ListItem enumerate(
            string _project, string _repo, ulong pageNumber = 0) @safe;
}

/**
 * Base API for the Endpoints (Vessel)
 */
@path("/api/v1/endpoints")
public interface EndpointsAPIv1
{
    /**
     * Enumerate endpoint attachments
     */
    @path("enumerate") @method(HTTPMethod.GET) ListItem[] enumerate() @safe;

    /**
     * Create an endpoint attachment
     */
    @path("create") @method(HTTPMethod.POST) void create(AttachEndpoint request) @safe;
}

/**
 * Base API for the Tasks service
 */
@path("/api/v1/tasks")
public interface TasksAPIV1
{
    /**
     * Enumerate all tasks
     */
    @path("enumerate") @method(HTTPMethod.GET) Paginator!ListItem enumerate(ulong pageNumber = 0) @safe;
}

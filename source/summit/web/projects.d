/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.projects
 *
 * Projects Web API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.web.projects;

import moss.deps.registry;
import moss.service.context;
import std.range : empty, front;
import summit.projects;
import vibe.d;

/**
 * Root entry into our web service
 */
@path("/~")
public final class ProjectsWeb
{
    @disable this();

    /**
     * Construct a new ProjectsWeb
     *
     * Params:
     *      context = global context
     */
    this(ServiceContext context, ProjectManager projectManager) @safe
    {
        this.context = context;
        this.projectManager = projectManager;
    }

    /**
     * Projects index
     */
    void index() @safe
    {
        render!"projects/index.dt";
    }

    /**
     * View an individual project
     *
     * Params:
     *      _slug = Specific slug ID (i.e. project short name)
     */
    @path("/:slug") @method(HTTPMethod.GET)
    void view(string _slug)
    {
        auto project = projectManager.bySlug(_slug);
        enforceHTTP(project !is null, HTTPStatus.notFound);
        render!("projects/view.dt", project);
    }

    /**
     * View a repo within a project
     *
     * Params:
     *      _slug = Project ID
     *      _repo = Repo ID
     */
    @path("/:slug/:repo") @method(HTTPMethod.GET)
    void viewRepo(string _slug, string _repo)
    {
        auto project = projectManager.bySlug(_slug);
        enforceHTTP(project !is null, HTTPStatus.notFound);
        auto repository = project.bySlug(_repo);
        enforceHTTP(repository !is null, HTTPStatus.notFound);
        render!("projects/repo.dt", project, repository);
    }

    /** 
     * View a recipe within a specific project's repository
     *
     * Params:
     *      _slug = Project ID
     *      _repo = Repository ID
     *      _recipeID = Recipe ID
     */
    @path("/:slug/:repo/:recipeID") @method(HTTPMethod.GET)
    void viewRecipe(string _slug, string _repo, string _recipeID) @safe
    {
        auto project = projectManager.bySlug(_slug);
        enforceHTTP(project !is null, HTTPStatus.notFound);
        auto repository = project.bySlug(_repo);
        enforceHTTP(repository !is null, HTTPStatus.notFound);

        auto items = repository.db.byProvider(ProviderType.PackageName, _recipeID);
        enforceHTTP(!items.empty, HTTPStatus.notFound);
        auto recipe = repository.db.byID(items.front);
        render!("projects/recipe.dt", project, repository, recipe);
    }

private:

    ServiceContext context;
    ProjectManager projectManager;
}

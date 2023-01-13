/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.recipes
 *
 * V1 Summit Recipes API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.recipes;

public import summit.api.v1.interfaces;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import std.algorithm : map, sort;
import std.array : array;
import summit.projects;
import vibe.d;

/**
 * Implements the RecipesAPIv1
 */
public final class RecipesService : RecipesAPIv1
{
    @disable this();

    /**
     * Construct new RecipesService
     *
     * Params:
     *      context = global context
     *      projectManager = project manager
     */
    this(ServiceContext context, ProjectManager projectManager) @safe
    {
        this.context = context;
        this.projectManager = projectManager;
    }

    /**
     * Enumerate all of the recipes
     *
     * Params:
     *      _project: Project slug
     *      _repo: Repo slug
     *
     * Returns: ListItem[] of known repos
     */
    override Paginator!ListItem enumerate(string _project, string _repo, ulong pageNumber = 0) @safe
    {
        ListItem[] ret;
        auto project = projectManager.bySlug(_project);
        enforceHTTP(project !is null, HTTPStatus.notFound, "Project not found");
        auto repo = project.bySlug(_repo);
        enforceHTTP(repo !is null, HTTPStatus.notFound, "Repository not found");

        auto items = repo.db.list.map!((i) {
            ListItem item;
            item.id = i.pkgID;
            item.context = ListContext.Recipes;
            item.title = format!"%s - %s-%s"(i.sourceID, i.versionIdentifier, i.sourceRelease);
            item.slug = format!"/~/%s/%s/%s"(_project, _repo, i.sourceID);
            item.subtitle = i.summary;
            return item;
        });
        ret = () @trusted { return items.array; }();
        ret.sort!((a, b) => a.title < b.title);
        return Paginator!ListItem(ret, pageNumber);
    }

private:
    ServiceContext context;
    ProjectManager projectManager;
}

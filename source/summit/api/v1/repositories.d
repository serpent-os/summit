/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.repositories
 *
 * V1 Summit Repositories API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.repositories;

public import summit.api.v1.interfaces;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import std.algorithm : filter, map;
import std.array : array;
import summit.projects;
import summit.models.project;
import summit.models.repository;
import vibe.d;

/**
 * Implements the ProjectsAPIv1
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
    this(ServiceContext context, ProjectManager projectManager) @safe
    {
        this.context = context;
        this.projectManager = projectManager;
    }

    /**
     * Enumerate all of the repos
     *
     * Params:
     *      _project: Project slug
     *
     * Returns: ListItem[] of known repos
     */
    override ListItem[] enumerate(string _project) @safe
    {
        ManagedProject project = projectManager.bySlug(_project);
        enforceHTTP(projectManager !is null, HTTPStatus.notFound);

        auto ret = project.repositories.map!((r) {
            ListItem item;
            item.id = to!string(r.model.id);
            item.title = r.model.name;
            item.slug = format!"/~/%s/%s"(_project, r.model.name);
            item.subtitle = r.model.summary;
            item.context = ListContext.Repositories;
            return item;
        });
        return () @trusted { return ret.array; }();
    }

private:
    ServiceContext context;
    ProjectManager projectManager;
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.projects
 *
 * V1 Summit Projects API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.projects;

public import summit.api.v1.interfaces;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import std.algorithm : map;
import std.array : array;
import summit.projects;
import summit.models.project;
import vibe.d;

/**
 * Implements the ProjectsAPIv1
 */
public final class ProjectsService : ProjectsAPIv1
{
    @disable this();

    /**
     * Construct new ProjectsService
     *
     * Params:
     *      context = global context
     *      projectManager = Project management
     */
    this(ServiceContext context, ProjectManager projectManager) @safe
    {
        this.context = context;
        this.projectManager = projectManager;
    }

    /**
     * Enumerate all of the projects
     *
     * Returns: ListItem[] of known projects
     */
    override ListItem[] enumerate() @safe
    {
        auto ret = projectManager.projects.map!((c) {
            ListItem ret;
            ret.context = ListContext.Projects;
            ret.id = to!string(c.model.id);
            ret.title = c.model.name;
            ret.subtitle = c.model.summary;
            ret.slug = format!"/~/%s"(c.model.slug);
            return ret;
        });
        return () @trusted { return ret.array; }();
    }

private:
    ServiceContext context;
    ProjectManager projectManager;
}

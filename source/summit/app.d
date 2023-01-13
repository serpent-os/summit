/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.app
 *
 * Core application lifecycle
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.app;

import moss.core.errors;
import moss.service.accounts;
import moss.service.context;
import moss.service.models;
import std.path : buildPath;
import summit.api;
import summit.build;
import summit.fixtures;
import summit.models;
import summit.projects;
import summit.web;
import vibe.d;

/**
 * SummitApplication provides the main dashboard application
 * seen by users after the setup app is complete.
 */
public final class SummitApplication
{
    @disable this();

    /**
     * Construct new App 
     *
     * Params:
     *      context = application context
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
        this.projectManager = new ProjectManager(context);
        this.buildManager = new BuildManager(context, projectManager);
        immutable err = projectManager.connect();
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        _router = new URLRouter();
        web = new SummitWeb(context, projectManager, router);
        service = new RESTService(context, projectManager, router);

        loadFixtures(context, projectManager);
    }

    /**
     * Returns: mapped router
     */
    pragma(inline, true) pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

    /**
     * Close down the app/instance
     */
    void close() @safe
    {
        projectManager.close();
    }

private:

    ProjectManager projectManager;
    BuildManager buildManager;
    ServiceContext context;
    RESTService service;
    URLRouter _router;
    SummitWeb web;
}

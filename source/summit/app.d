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
import summit.dispatch;
import moss.service.server;

/**
 * SummitApplication provides the main dashboard application
 * seen by users after the setup app is complete.
 */
public final class SummitApplication : Application
{
    override void initialize(ServiceContext context) @safe
    {
        this.context = context;
        this.projectManager = new ProjectManager(context);
        immutable err = projectManager.connect();
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        this.buildQueue = new BuildQueue(context, projectManager);
        worker = new DispatchWorker(context, buildQueue, projectManager);

        _router = new URLRouter();
        web = new SummitWeb(context, projectManager, router);
        service = new RESTService(context, projectManager, router);

        loadFixtures(context, projectManager);

        /* Now get the dispatch worker going */
        worker.start();
    }

    /**
     * Returns: mapped router
     */
    @noRoute override pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

    /**
     * Close down the app/instance
     */
    override void close() @safe
    {
        projectManager.close();
        worker.stop();
    }

private:

    ProjectManager projectManager;
    BuildQueue buildQueue;
    DispatchWorker worker;
    ServiceContext context;
    RESTService service;
    URLRouter _router;
    SummitWeb web;
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1
 *
 * V1 Summit API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.api.v1;

public import vibe.d;
public import summit.api.v1.interfaces;

import moss.service.context;
import moss.service.pairing;
import summit.api.v1.builders;
import summit.api.v1.endpoints;
import summit.api.v1.pairing;
import summit.api.v1.projects;
import summit.api.v1.recipes;
import summit.api.v1.reporting;
import summit.api.v1.repositories;
import summit.api.v1.tasks;
import summit.dispatch.worker : DispatchChannel;
import summit.projects;

/**
 * Root implementation to configure all supported interfaces
 */
public final class RESTService : SummitAPIv1
{
    @disable this();

    /**
     * Construct the new RESTService root
     *
     * Params:
     *      context = global context
     *      projectManager = Project management
     *      channel = Dispatch workers bus
     *      router = nested router
     */
    this(ServiceContext context, ProjectManager projectManager,
            PairingManager pairingManager, DispatchChannel channel, URLRouter router) @safe
    {
        router.registerRestInterface(this);
        router.registerRestInterface(new BuildersService(context, pairingManager));
        router.registerRestInterface(new ProjectsService(context, projectManager));
        router.registerRestInterface(new EndpointsService(context, pairingManager));
        router.registerRestInterface(new RepositoriesService(context, projectManager));
        router.registerRestInterface(new RecipesService(context, projectManager));
        router.registerRestInterface(new ReportingService(context, channel));
        router.registerRestInterface(new PairingService(context, pairingManager));
        router.registerRestInterface(new TasksService(context));
    }

    /**
     * Returns: Version identifier
     */
    override string versionID() @safe @nogc nothrow const
    {
        return "0.0.1";
    }

private:

    string rootDir;
}

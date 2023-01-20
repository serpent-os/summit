/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.dispatch.worker
 *
 * Core program flow for Summit. Centralisation for the
 * BuildQueue, ProjectManager, etc.
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.dispatch.worker;

import moss.service.context;
import moss.service.interfaces.avalanche;
import moss.service.models;
import std.algorithm : filter;
import std.array : array;
import std.range : StoppingPolicy, zip;
import summit.build;
import summit.dispatch.messaging;
import summit.models;
import summit.projects;
import vibe.core.channel;
import vibe.d;

/** 
 * Dispatch event channel
 */
public alias DispatchChannel = Channel!(DispatchEvent, 1_000);

/** 
 * Control the primary flow of the program and dispatch
 * updates, handle events, etc.
 */
public final class DispatchWorker
{
    @disable this();

    /** 
     * Construct a new DispatchWorker
     *
     * Params:
     *   context = global service context
     *   buildQueue =  global build manager
     *   projectManager = global project management
     */
    this(ServiceContext context, BuildQueue buildQueue, ProjectManager projectManager) @safe
    {
        this.context = context;
        this.buildQueue = buildQueue;
        this.projectManager = projectManager;

        controlChannel = createChannel!(DispatchEvent, 1_000);
    }

    /** 
     * Start the main execution loop, message based.
     */
    void start() @safe
    {
        runTask(&dispatchLoop);

        /* Immediately create a timer event to update the projects */
        DispatchEvent time = TimerInterruptEvent(30.seconds, true);
        controlChannel.put(time);
    }

    /** 
     * Stop the main execution loop
     */
    void stop() @safe
    {
        controlChannel.close();
        systemTimer.stop();
    }

private:

    /** 
     * Continously listen to the event queue
     */
    void dispatchLoop() @safe
    {
        logInfo("dispatchLoop: Running");
        DispatchEvent event;

        /* Listen forever until the channels closed */
        while (controlChannel.tryConsumeOne(event))
        {
            logDiagnostic(format!"dispatchLoop: event [%s] started"(event.kind));

            final switch (event.kind)
            {
            case DispatchEvent.Kind.allocateBuilds:
                handleBuildAllocations(cast(AllocateBuildsEvent) event);
                break;
            case DispatchEvent.Kind.timer:
                handleTimer(cast(TimerInterruptEvent) event);
                break;
            }

            logDiagnostic(format!"dispatchLoop: event [%s] finished"(event.kind));
        }

        logInfo("dispatchLoop: Ended");
    }

    /**
     * Handle our core timer - update projects at controlled event
     *
     * Params:
     *   event = Timed event (30 seconds)
     */
    void handleTimer(TimerInterruptEvent event) @safe
    {
        /* TODO: For all changed projects, notify the build manager */
        auto changedRepositories = projectManager.updateProjects();
        foreach (repo; changedRepositories)
        {
            logDiagnostic(format!"Checking %s for builds"(repo.model));
            buildQueue.checkMissingWithinRepo(repo.project, repo);
        }

        DispatchEvent builder = AllocateBuildsEvent();
        controlChannel.put(builder);

        /* Reinstall the timer? */
        if (event.recurring)
        {
            () @trusted {
                systemTimer = setTimer(event.interval, () {
                    controlChannel.put(DispatchEvent(event));
                });
            }();
        }
    }

    /** 
     * We need to check for any free build slots and pass them off,
     * if possible, to an available builder.
     * We only use the "live" jobs, i.e. 0 numDeps.
     *
     * Params:
     *   event = Build allocation event
     */
    void handleBuildAllocations(AllocateBuildsEvent event) @safe
    {
        buildQueue.recomputeQueue();
        auto availableJobs = buildQueue.availableJobs;
        if (availableJobs.empty)
        {
            logDiagnostic("No builds available for allocation right now");
            return;
        }

        /* TODO: Sort available builders + jobs by weight, filter inappropriate builders (architecture) */
        /* Attempt to schedule via available builders */
        auto workerMapping = zip(StoppingPolicy.shortest, availableBuilders, availableJobs);
        if (workerMapping.empty)
        {
            logDiagnostic("No builder available right now");
            return;
        }

        foreach (builder, job; workerMapping)
        {
            logDiagnostic(format!"Builder %s will now build %s"(builder.id, job.entry.sourceID));
            buildOne(builder, job);
        }
    }

    /**
     * Grab a list of the builders immediately available
     */
    auto availableBuilders() @safe
    {
        AvalancheEndpoint[] endpoints;

        context.appDB.view((in tx) @safe {
            auto results = tx.list!AvalancheEndpoint
                .filter!((e) => e.status == EndpointStatus.Operational
                    && e.workStatus == WorkStatus.Idle);
            endpoints = () @trusted { return results.array; }();
            return NoDatabaseError;
        });
        return endpoints;
    }

    /** 
     * Build a single package
     *
     * This is sent via a specific endpoint using our issue token.
     * Until such point as the build status returns, we consider the item
     * building, and the builder as non-idle.
     *
     * Note: We have to check our tokens are up to date here
     *
     * Params:
     *   endpoint = Endpoint that will take the build
     *   job = Job to perform / build
     */
    void buildOne(ref AvalancheEndpoint endpoint, in JobMapper job) @safe
    {
        auto api = new RestInterfaceClient!AvalancheAPI(endpoint.hostAddress);
        api.requestFilter = (req) {
            req.headers["Authorization"] = format!"Bearer %s"(endpoint.apiToken);
        };

        PackageBuild buildDef;
        Repository modRepo;
        Project modProject;
        Profile modProfile;

        /* Install remote config */
        foreach (i, rm; job.remotes)
        {
            auto c = BinaryCollection(rm, format!"repo%d"(i), (cast(uint) i) * 10);
            buildDef.collections ~= c;
        }

        /* Look up the model to grab some deets */
        immutable err = context.appDB.view((in tx) @safe {
            auto e1 = modRepo.load(tx, job.task.repoID);
            if (!e1.isNull)
            {
                return e1;
            }
            auto e2 = modProfile.load(tx, job.task.profileID);
            if (!e2.isNull)
            {
                return e2;
            }
            return modProject.load(tx, job.task.projectID);
        });
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);

        /* Construct full build definition */
        auto project = projectManager.bySlug(modProject.slug);
        auto profile = project.profile(modProfile.name);
        buildDef.buildArchitecture = modProfile.arch;
        buildDef.commitRef = job.task.commitRef;
        buildDef.relativePath = job.task.sourcePath;
        buildDef.uri = modRepo.originURI;
        buildDef.buildID = job.task.id;

        /* Defer status */
        BuildTaskStatus newBuildStatus;
        WorkStatus newWorkstatus;

        try
        {
            /* Please work */
            api.buildPackage(buildDef, NullableToken());
            newBuildStatus = BuildTaskStatus.Building;
            newWorkstatus = WorkStatus.Working;
        }
        catch (Exception ex)
        {
            /* TODO: Block dependents in the queue */
            logError(format!"Exception in buildOne: %s"(ex.message));
            newBuildStatus = BuildTaskStatus.Failed;
            newWorkstatus = WorkStatus.Idle;
        }

        endpoint.workStatus = newWorkstatus;
        auto err2 = context.appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err2.isNull, HTTPStatus.internalServerError, err2.message);
        buildQueue.updateTask(buildDef.buildID, newBuildStatus);
    }

    DispatchChannel controlChannel;
    ServiceContext context;
    BuildQueue buildQueue;
    ProjectManager projectManager;
    Timer systemTimer;
}

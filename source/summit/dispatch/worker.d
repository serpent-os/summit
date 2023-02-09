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
import moss.service.tokens.refresh;
import std.algorithm : filter;
import std.array : array;
import std.range : front, popFront;
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

    /** 
     * Returns: Control Channel
     */
    pure @property auto channel() @safe @nogc nothrow
    {
        return controlChannel;
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
            case DispatchEvent.Kind.buildFailed:
                handleBuildFailure(cast(BuildFailedEvent) event);
                break;
            case DispatchEvent.Kind.buildSucceeded:
                handleBuildSuccess(cast(BuildSucceededEvent) event);
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

        auto builders = availableBuilders();
        job_loop: foreach (job; availableJobs)
        {
            /* Copied slice to work with */
            auto testBuilders = builders[0 .. $];
            do
            {
                /* No more usable builders */
                if (testBuilders.empty)
                {
                    break job_loop;
                }
                AvalancheEndpoint builder = testBuilders.front;
                testBuilders.popFront();

                /* Baad builder */
                if (!builder.ensureEndpointUsable(context))
                {
                    import std.algorithm : remove;

                    builders = builders.remove!((b) => b.id == builder.id);
                    testBuilders = builders[0 .. $];
                    continue;
                }
                else
                {
                    buildOne(builder, job);
                    break;
                }
            }
            while (true);
            builders = availableBuilders();
            availableJobs = buildQueue.availableJobs;

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
            logError(format!"Exception in buildOne: %s"(ex.message));
            newBuildStatus = BuildTaskStatus.Failed;
            newWorkstatus = WorkStatus.Idle;
        }

        endpoint.workStatus = newWorkstatus;
        auto err2 = context.appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err2.isNull, HTTPStatus.internalServerError, err2.message);
        buildQueue.updateTask(buildDef.buildID, newBuildStatus);
    }

    /** 
     * Avalanche reports a build has failed - deal with it.
     *
     * Params:
     *   event = build event
     */
    void handleBuildFailure(BuildFailedEvent event) @safe
    {
        AvalancheEndpoint endpoint;

        /* First thing, make the builder available again */
        immutable err = context.appDB.update((scope tx) @safe {
            auto err = endpoint.load(tx, event.builderID);
            if (!err.isNull)
            {
                return err;
            }
            endpoint.workStatus = WorkStatus.Idle;
            logDiagnostic(format!"Avalanche builder now idle: %s"(endpoint.id));
            return endpoint.save(tx);
        });

        logError(format!"Avalanche instance '%s' reports task failure for #%s"(endpoint.id,
                event.taskID));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        buildQueue.updateTask(event.taskID, BuildTaskStatus.Failed);
    }

    /** 
     * Avalanche reports a build has succeeded - deal with it
     * Params:
     *   event = build event
     */
    void handleBuildSuccess(BuildSucceededEvent event) @safe
    {
        AvalancheEndpoint endpoint;

        /* First thing, make the builder available again */
        immutable err = context.appDB.update((scope tx) @safe {
            auto err = endpoint.load(tx, event.builderID);
            if (!err.isNull)
            {
                return err;
            }
            endpoint.workStatus = WorkStatus.Idle;
            logDiagnostic(format!"Avalanche builder now idle: %s"(endpoint.id));
            return endpoint.save(tx);
        });

        logInfo(format!"Avalanche instanxce '%s' reports task succeess for #%s (%s)"(endpoint.id,
                event.taskID, event.collectables));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* TOOD: Mark as publishing */
        buildQueue.updateTask(event.taskID, BuildTaskStatus.Completed);
    }

    DispatchChannel controlChannel;
    ServiceContext context;
    BuildQueue buildQueue;
    ProjectManager projectManager;
    Timer systemTimer;
}

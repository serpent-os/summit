/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.dispatch.worker
 *
 * Core program flow for Summit. Centralisation for the
 * BuildManager, ProjectManager, etc.
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.dispatch.worker;

import moss.service.context;
import summit.build;
import summit.dispatch.messaging;
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
     *   buildManager =  global build manager
     *   projectManager = global project management
     */
    this(ServiceContext context, BuildManager buildManager, ProjectManager projectManager) @safe
    {
        this.context = context;
        this.buildManager = buildManager;
        this.projectManager = projectManager;

        controlChannel = createChannel!(DispatchEvent, 1_000);
    }

    /** 
     * Start the main execution loop, message based.
     */
    void start() @safe
    {
        runTask(&dispatchLoop);

        /* Immediately create a timer event */
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
        projectManager.updateProjects();

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

    DispatchChannel controlChannel;
    ServiceContext context;
    BuildManager buildManager;
    ProjectManager projectManager;
    Timer systemTimer;
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

module summit.workers.system;

/**
 * summit.workers.system
 *
 * Implements the worker bee system (Task scheduling)
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

import vibe.d;
import vibe.core.channel;
import vibe.core.core : yield;
import summit.workers.async_worker;
public import summit.workers.job;

/**
 * Provides a task system with persistence to allow
 * scheduling events to take place
 */
public final class WorkerSystem
{

    /**
     * Construct and initialise the WorkerSystem
     */
    this() @safe
    {
        event = createSharedManualEvent();
        static ChannelConfig channelConfig = ChannelConfig(ChannelPriority.latency);
        asyncChannel = createChannel!(WorkerTask, taskBacklog)(channelConfig);
    }

    /**
     * Start the worker system.
     */
    void start() @safe
    {
        mainTask = runTask(&mainTaskRun);
        () @trusted {
            runWorkerTaskDistH(&appendTask, &workerFunction, asyncChannel);
        }();
    }

    /**
     * Stop the worker system
     */
    void stop() @safe
    {
        if (!mainTask.running)
        {
            return;
        }
        logInfo(" >>> Shutting down WorkerSystem");
        running = false;
        event.emit();
        mainTask.join();

        /* Stop the job queue */
        asyncChannel.close();

        /* Shut down the async tasks. Awaiting completion */
        foreach (ref task; asyncTasks)
        {
            task.join();
        }
    }

private:

    /**
     * runWorkerTaskDistH callback.
     *
     * Params:
     *      h = Task handle
     */
    void appendTask(scope Task h) @safe
    {
        asyncTasks ~= h;
    }

    /**
     * Main thread events..
     */
    void mainTaskRun() @safe
    {
        running = true;
        while (running)
        {
            event.wait(0);
            yield;
        }
    }

    /**
     * Event to wake us up if someones got something.
     */
    shared(ManualEvent) event;

    /**
     * Backlogged worker system
     */
    WorkerChannel asyncChannel;

    /**
     * Reference to the main fiber
     */
    Task mainTask;

    /**
     * Async workers - god love 'em
     */
    Task[] asyncTasks;

    /**
     * We still running..?
     */
    bool running;
}

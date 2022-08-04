/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

module summit.workers.job;

public import vibe.core.channel : Channel;
public import std.stdint : uint8_t, uint64_t;

import moss.db.keyvalue.orm;
import std.datetime.systime;

/**
 * summit.workers.job
 *
 * Base "job" types
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

/**
 * Each Task has a unique ID.
 */
public alias TaskID = uint64_t;

/**
 * Represents the current task status
 */
public enum TaskStatus : uint8_t
{
    /**
     * Newly created - not even looked at it.
     */
    Awaiting = 0,

    /**
     * Currently "going"
     */
    Running,

    /**
     * This task has succeeded
     */
    Succeeded,

    /**
     * This task has failed
     */
    Failed,
}

/**
 * A scheduled task
 */
public struct WorkerTask
{
    /**
     * Unique identity for each task.
     */
    @PrimaryKey @AutoIncrement TaskID id;

    /**
     * Status for this task
     */
    TaskStatus status;

    /**
     * When was the task created?
     */
    SysTime tsCreated;

    /**
     * When did execution start?
     */
    SysTime tsStarted;

    /**
     * When did it finish?
     */
    SysTime tsFinished;

    /**
     * Is this actually done yet?
     *
     * Returns: true if the task finished (or failed.)
     */
    pragma(inline, true) pure @property bool finished() @safe @nogc nothrow
    {
        return (status == TaskStatus.Failed) || (status == TaskStatus.Succeeded);
    }
}

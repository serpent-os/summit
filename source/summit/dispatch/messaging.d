/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.dispatch.messaging
 *
 * Event messaging types
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.dispatch.messaging;

public import taggedalgebraic.taggedalgebraic;
import std.datetime : Duration;
import vibe.d;
public import summit.models.buildtask : BuildTaskID;
public import moss.service.interfaces : Collectable;

/** 
 * A TimerInterruptEvent is sent by a core timer.
 * Currently it's only used as a way to refresh the
 * project repositories.
 */
public struct TimerInterruptEvent
{
    /** 
     * Duration between updates
     */
    Duration interval;

    /** 
     * When true, reschedule the event
     */
    bool recurring;
}

/** 
 * The dispatch loop should hand out any available builds.
 */
public struct AllocateBuildsEvent
{

}

/**
 * A build managed to succeed - reindexing required
 */
public struct BuildSucceededEvent
{
    BuildTaskID taskID;
    string builderID;
    Collectable[] collectables;
}

/**
 * A build failed - no reindexing necessary
 */
public struct BuildFailedEvent
{
    BuildTaskID taskID;
    string builderID;
    Collectable[] collectables;
}

/** 
 * A build has been imported - reindexing necessary
 */
public struct ImportSucceededEvent
{
    BuildTaskID taskID;
    string vesselID;
}

/** 
 * A build failed to import - no reindexing necessary
 */
public struct ImportFailedEvent
{
    BuildTaskID taskID;
    string vesselID;
}
/**
 * Define the types supported by our algebraic event type
 */
public union DispatchEventTypes
{
    /** 
     * Event scheduled to happen at this time
     */
    TimerInterruptEvent timer;

    /** 
     * Time to allocate some builds
     */
    AllocateBuildsEvent allocateBuilds;

    /**
     * Build failure (Avalanche)
     */
    BuildFailedEvent buildFailed;

    /**
     * Build succeeded (Avalanche)
     */
    BuildSucceededEvent buildSucceeded;

    /** 
     * Import failed (vessel)
     */
    ImportFailedEvent importFailed;

    /** 
     * Import succeeded (vessel)
     */
    ImportSucceededEvent importSucceeded;
}

/** 
 * Core event type - fully baked
 */
public alias DispatchEvent = TaggedAlgebraic!DispatchEventTypes;

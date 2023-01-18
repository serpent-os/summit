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

/** 
 * A TimerInterruptEvent is sent by a core timer.
 * Currently it's only used as a way to refresh the
 * project repositories.
 */
public struct TimerInterruptEvent
{
    /** 
     * Frequency of updates
     */
    Duration interval;
}

/**
 * Define the types supported by our algebraic event type
 */
public union DispatchEventTypes
{
    /** 
     * An interrupt event happened at a controlled frequency
     */
    TimerInterruptEvent timer;
}

/** 
 * Core event type - fully baked
 */
public alias DispatchEvent = TaggedAlgebraic!DispatchEventTypes;

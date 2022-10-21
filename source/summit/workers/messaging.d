/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.workers.messaging
 *
 * Messaging module
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.workers.messaging;

public import vibe.core.channel;
public import taggedalgebraic;
public import summit.models.repository : Repository;

/**
 * Import the given repository
 */
public struct ImportRepositoryEvent
{
    /**
     * Repo to import
     */
    Repository repo;
}

/**
 * Refresh the given repository
 */
public struct RefreshRepositoryEvent
{
    /**
     * Repo to refresh
     */
    Repository repo;
}

/**
 * We need to rescan all manifests in the given repository
 */
public struct ScanManifestsEvent
{
    /**
     * Which repo we need to scan from
     */
    Repository repo;
}

/**
 * A set of known events
 */
public union ControlEventSet
{
    /**
     * We must import the given repo
     */
    ImportRepositoryEvent importRepo;

    /**
     * We must refresh the given repo (interval based)
     */
    RefreshRepositoryEvent refreshRepo;

    /**
     * Refresh the manifests
     */
    ScanManifestsEvent scanManifests;
}

/**
 * ControlEvents are nicely tagged algebraic events.
 */
public alias ControlEvent = TaggedAlgebraic!ControlEventSet;

/**
 * Backlog of 1k events.
 */
public static immutable auto numEvents = 1_000;

/**
 * Control queue is formed from control events
 */
public alias ControlQueue = Channel!(ControlEvent, numEvents);

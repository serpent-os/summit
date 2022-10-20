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
public import summit.models.collection : PackageCollectionID;

/**
 * We need to rescan all repositories
 */
public struct ScanRepositoriesEvent
{
    /**
     * Which collection we need to scan from
     */
    PackageCollectionID collectionID;
}

/**
 * A set of known events
 */
public union ControlEventSet
{
    ScanRepositoriesEvent scanRepositories;
}

public alias ControlEvent = TaggedAlgebraic!ControlEventSet;
public static immutable auto numEvents = 1_000;

/**
 * Control queue is formed from control events
 */
public alias ControlQueue = Channel!(ControlEvent, numEvents);

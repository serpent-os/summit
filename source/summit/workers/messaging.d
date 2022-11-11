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
public import moss.service.models.endpoints;

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
 * Update the given repository
 *
 * This happens only on the green queue
 */
public struct UpdateRepositoryEvent
{
    /**
     * Repository metadata to update
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
 * Requesting import of a manifest file
 */
public struct ImportManifestEvent
{
    /**
     * What repo are we importing into
     */
    Repository repo;

    /**
     * Full path for the manifest
     */
    string manifestPath;

    /**
     * Base directory for the repository
     */
    string basePath;
}

/**
 * We've got a new endpoint added but it needs enroling into
 * our system.
 */
public struct EnrolAvalancheEvent
{
    /**
     * The target endpoint. We'll form our own enrolment request
     */
    AvalancheEndpoint endpoint;
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
     * Metadata updated
     */
    UpdateRepositoryEvent updateRepo;

    /**
     * Refresh the manifests
     */
    ScanManifestsEvent scanManifests;

    /**
     * Import a single manifest path
     */
    ImportManifestEvent importManifest;

    /**
     * Enrol a builder
     */
    EnrolAvalancheEvent enrolBuilder;
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

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.buildtask
 *
 * Model for task tracking
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.models.buildtask;

import moss.db.keyvalue.orm;
public import std.stdint : uint8_t, uint64_t;
import summit.models.project : ProjectID;
import summit.models.profile : ProfileID;
import summit.models.repository : RepositoryID;

/**
 * Unique integer ID for tasks
 */
public alias BuildTaskID = uint64_t;

/**
 * Control flow for build tasks
 */
public enum BuildTaskStatus : uint8_t
{
    /**
     * Freshly created task, unchecked
     */
    New = 0,

    /**
     * Depending on other tasks completing.
     */
    Pending,

    /**
     * Ready for inclusion
     */
    Ready,

    /**
     * Failed execution or evaluation
     */
    Failed,

    /**
     * This task is now building
     */
    Building,

    /**
     * Now publishing to Vessel
     */
    Publishing,

    /**
     * Job successfully completed!
     */
    Completed,
}

/**
 * Build tasks are used to manage the control flow of scheduled jobs
 */
public @Model struct BuildTask
{
    /**
     * Unique task identifier
     */
    @PrimaryKey @AutoIncrement BuildTaskID id;

    /**
     * Project ID?
     */
    ProjectID projectID;

    /**
     * What repository owns the recipe?
     */
    RepositoryID repoID;

    /**
     * What we building with here?
     */
    ProfileID profileID;

    /**
     * Identity for the thing being built
     */
    string slug;

    /**
     * Unique pkgID in source manifest
     */
    string pkgID;

    /**
     * Buildable ID for display use
     */
    @Indexed string buildID;

    /**
     * Representable string in the UI
     */
    string description;

    /**
     * The repository commit ref at the time of scheduling
     */
    string commitRef;

    /**
     * Source path in the repo
     */
    string sourcePath;

    /**
     * Current status.
     */
    BuildTaskStatus status;

    /**
     * UTC Unix Timestamp: Started
     */
    uint64_t tsStarted;

    /**
     * UTC Unix Timestamp: Updated
     */
    uint64_t tsUpdated;

    /**
     * UTC Unix Timestamp: Ended
     */
    uint64_t tsEnded;
}

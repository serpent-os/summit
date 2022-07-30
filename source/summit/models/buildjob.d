/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.buildjob
 *
 * Build job encapsulation
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.models.buildjob;

public import std.stdint : uint8_t, uint64_t;
public import summit.models.user : UserIdentifier;

public import moss.db.keyvalue.orm;

/**
 * Our UID is the biggest number we can get.
 */
public alias BuildJobIdentifier = uint64_t;

/**
 * A Build Job is an actual buildable thingy in the queue
 */
public @Model struct BuildJob
{

    /**
     * Unique identifier for the group
     */
    @PrimaryKey @AutoIncrement BuildJobIdentifier id;
    
    /**
     * What are we building, exactly?
     */
    string resource;

    /**
     * What reference, if any, are we building?
     */
    string reference;

    /**
     * Who submitted the build?
     */
    UserIdentifier submitter;
}

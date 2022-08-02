/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.group
 *
 * Group encapsulation
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.models.group;

public import std.stdint : uint8_t, uint64_t;
public import summit.models.user : UserIdentifier;

public import moss.db.keyvalue.orm;

/**
 * Our UID is the biggest number we can get.
 */
public alias GroupIdentifier = uint64_t;

/**
 * A Group is a collection of users
 */
public @Model struct Group
{

    /**
     * Unique identifier for the group
     */
    @PrimaryKey @AutoIncrement GroupIdentifier id;

    /** 
     * Unique slug for the whole instance
     */
    @Indexed string slug;

    /**
     * Display name
     */
    string name;

    /**
     * All the users within our group
     */
    UserIdentifier[] users;
}

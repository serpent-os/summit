/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.namespace
 *
 * Namespace encapsulation
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.models.namespace;

public import std.stdint : uint8_t, uint64_t;

public import moss.db.keyvalue.orm;
public import summit.models.project : ProjectIdentifier;

/**
 * Our UID is the biggest number we can get.
 */
public alias NamespaceIdentifier = uint64_t;

/**
 * A Group is a collection of users
 */
public @Model struct Namespace
{

    /**
     * Unique identifier for the group
     */
    @PrimaryKey @AutoIncrement NamespaceIdentifier id;

    /** 
     * Unique slug for the whole instance
     */
    @Indexed string slug;

    /**
     * Display name
     */
    string name;

    /**
     * Brief details of the namespace
     */
    string summary;

    /**
     * Full on README.md of a namespace
     */
    string description;

    /**
     * All the users within our group
     */
    ProjectIdentifier[] projects;
}

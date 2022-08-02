/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.project
 *
 * Project encapsulation
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.models.project;

public import std.stdint : uint8_t, uint64_t;
public import summit.models.namespace : NamespaceIdentifier;
public import moss.db.keyvalue.orm;

/**
 * Our UID is the biggest number we can get.
 */
public alias ProjectIdentifier = uint64_t;

/**
 * A Project is a collectio of packages
 */
public @Model struct Project
{

    /**
     * Unique identifier for the project
     */
    @PrimaryKey @AutoIncrement ProjectIdentifier id;

    /**
     * Unique slug for entire instance
     */
    @Indexed string slug;

    /**
     * Display name
     */
    string name;

    /**
     * A Project belongs in exactly *one* namespace
     */
    NamespaceIdentifier namespace;

    /**
     * Brief summary of the project
     */
    string summary;

    /**
     * Full description
     */
    string description;
}

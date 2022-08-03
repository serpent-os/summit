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

module summit.models.repository;

public import std.stdint : uint64_t;
public import summit.models.project : ProjectIdentifier;
public import moss.db.keyvalue.orm;

/**
 * Our UID is the biggest number we can get.
 */
public alias RepositoryIdentifier = uint64_t;

/**
 * We only support git. Git with the program.
 */
public enum VcsType
{
    Git = 0,
}

/**
 * A Repository belongs to a Project
 * In most cases it is a package.
 */
public @Model struct Repository
{

    /**
     * Unique identifier for the repo
     */
    @PrimaryKey @AutoIncrement RepositoryIdentifier id;

    /**
     * Unique slug for the project (projectID/slug)
     */
    @Indexed string slug;

    /**
     * Display name
     */
    string name;

    /**
     * Where is this thingy hosted?
     */
    string vcsOrigin;

    /**
     * What kind of repo is it
     */
    VcsType vcsType = VcsType.Git;

    /**
     * A Repository belongs to exactly one project
     */
    ProjectIdentifier project;
}

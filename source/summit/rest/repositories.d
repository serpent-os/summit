/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.rest.repositories
 *
 * API for Repository management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.rest.repositories;

import vibe.d;
import vibe.web.auth;

import moss.db.keyvalue;
import summit.accounts;
import summit.models.repository;

/**
 * The BuildJobs API
 */
@requiresAuth @path("api/v1/repositories") public interface RepositoryAPIv1
{
    /**
     * List all repositories within a given project slug
     */
    @noAuth @path(":namespace/:project/list") @method(HTTPMethod.GET) Repository[] list(
            string _namespace, string _project) @safe;
}

/**
 * Provide BuildJob management
 */
public final class RepositoryAPI : RepositoryAPIv1
{
    /**
     * Integrate into the root API
     */
    @noRoute void configure(URLRouter root, Database appDB, AccountManager accountManager) @safe
    {
        this.accountManager = accountManager;
        this.appDB = appDB;
        root.registerRestInterface(this);
    }

    mixin AppAuthenticator;

    /**
     * Grab all the active build jobs
     *
     * Returns: slice of active BuildJobs
     */
    override Repository[] list(string _namespace, string _project) @safe
    {
        return null;
    }

private:

    Database appDB;
    AccountManager accountManager;
}

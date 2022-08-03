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
import summit.models.project;
import summit.models.repository;
import std.algorithm : filter, sort;
import std.array : array;

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

    @noAuth @path(":namespace/:project/create") @method(HTTPMethod.POST) void create(
            string _namespace, string _project, string name, string upstream, string buildType) @safe;
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
        Repository[] ret;
        auto e = appDB.view((in tx) @safe {
            Project p;
            {
                auto err = p.load!"slug"(tx, _project);
                if (!err.isNull)
                {
                    return err;
                }
            }
            ret = tx.list!Repository
                .filter!((r) => r.project == p.id)
                .array;
            ret.sort!"a.name < b.name";
            return NoDatabaseError;
        });
        enforceHTTP(e.isNull, HTTPStatus.internalServerError, e.message);
        return ret;
    }

    /**
     * Attempt repo creation
     */
    override void create(string _namespace, string _project, string name,
            string upstream, string buildType) @safe
    {
        Repository r = Repository(0, name, name, upstream, VcsType.Git);
        r.vcsOrigin = upstream;
        Project p;
        auto e = appDB.update((scope tx) @safe {
            auto e = p.load!"slug"(tx, _project);
            if (!e.isNull)
            {
                return e;
            }
            r.project = p.id;
            return r.save(tx);
        });
        logInfo("Create %s %s %s", name, upstream, buildType);
        enforceHTTP(e.isNull, HTTPStatus.notFound, e.message);
    }

private:

    Database appDB;
    AccountManager accountManager;
}

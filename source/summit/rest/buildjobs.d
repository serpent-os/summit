/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.rest.buildjobs
 *
 * API for BuildJob management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.rest.buildjobs;

import vibe.d;
import vibe.web.auth;

import summit.accounts;
import summit.models.buildjob;
import moss.db.keyvalue;
import std.array : array;
import std.algorithm : reverse;

/**
 * The BuildJobs API
 */
@requiresAuth @path("api/v1/buildjobs") public interface BuildJobsAPIv1
{
    /**
     * List all active jobs
     */
    @noAuth @path("list_active") @method(HTTPMethod.GET) BuildJob[] listActive() @safe;

    /**
     * Create a new build job
     */
    @auth(Role.remoteAccess) @path("create") @method(HTTPMethod.PUT) void create(
            string target, string reference) @safe;
}

/**
 * Provide BuildJob management
 */
public final class BuildJobsAPI : BuildJobsAPIv1
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
    override BuildJob[] listActive() @safe
    {
        BuildJob[] jobs;
        appDB.view((in tx) @safe {
            /* TODO: Filter */
            jobs = tx.list!BuildJob().array;
            jobs.reverse();
            return NoDatabaseError;
        });
        return jobs;
    }

    /**
     * Create a new build job
     */
    override void create(string target, string reference) @safe
    {
        BuildJob job;
        job.reference = reference;
        job.resource = target;
        auto err = appDB.update((scope tx) => job.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        runTask(() @safe {
            sleep(2.seconds);
            auto err = appDB.update((scope tx) {
                job.status = JobStatus.Failed;
                return job.save(tx);
            });
        });
    }

private:

    Database appDB;
    AccountManager accountManager;
}

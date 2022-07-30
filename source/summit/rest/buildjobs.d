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

import summit.models.buildjob;
import moss.db.keyvalue;
import std.array : array;

/**
 * The BuildJobs API
 */
@path("api/v1/buildjobs") public interface BuildJobsAPIv1
{
    /**
     * List all active jobs
     */
    @path("list_active") @method(HTTPMethod.GET) BuildJob[] listActive() @safe;

    /**
     * Create a new build job
     */
    @path("create") @method(HTTPMethod.PUT) void create(string target, string reference) @safe;
}

/**
 * Provide BuildJob management
 */
public final class BuildJobsAPI : BuildJobsAPIv1
{
    /**
     * Integrate into the root API
     */
    @noRoute void configure(URLRouter root, Database appDB) @safe
    {
        this.appDB = appDB;
        root.registerRestInterface(this);
    }

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
        runTask(() @safe {
            sleep(2.seconds);
            auto err = appDB.update((scope tx) {
                job.status = JobStatus.Failed;
                return job.save(tx);
            });
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

private:

    Database appDB;
}

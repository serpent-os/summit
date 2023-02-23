/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.context
 *
 * Project management
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.projects.project;

import moss.db.keyvalue;
import std.conv : to;
import std.algorithm : filter;
import std.path : buildPath;
import summit.projects.profile;
import summit.projects.repository;
import moss.service.context;
import summit.models.profile;
import summit.models.project;
import summit.models.repository;
import moss.core.errors;
import vibe.d : runTask;
import vibe.core.channel;

/**
 * A project explicitly managed by Summit
 */
public final class ManagedProject
{
    @disable this();

    /** 
     * Construct a new ManagedProject
     *
     * Params:
     *      context = global context
     *      model = Database model
     */
    this(ServiceContext context, Project model) @safe
    {
        this.context = context;
        this._model = model;
        /* The ID field never changes */
        this._dbPath = context.dbPath.buildPath("projects", to!string(model.id));
    }

    /**
     * Returns: Underlying DB model
     */
    pure @property Project model() @safe @nogc nothrow
    {
        return _model;
    }

    /**
     * Returns: This project's managed repositories
     */
    pure @property auto repositories() @safe nothrow
    {
        return managedRepos.values;
    }

    /**
     * Returns: This project's managed profiles
     */
    pure @property auto profiles() @safe nothrow
    {
        return managedProfiles.values;
    }

    /** 
     * Returns: Repository within this project
     *
     * Params:
     *      slug = Unique identifier
     */
    pure @property auto bySlug(in string slug) @safe nothrow
    {
        auto repo = (slug in managedRepos);
        return repo ? *repo : null;
    }

    /**
     * Returns: Profile within this project
     *
     * Params:
     *      slug = Unique identifier
     */
    pure @property auto profile(in string slug) @safe nothrow
    {
        auto profile = (slug in managedProfiles);
        return profile ? *profile : null;
    }

    /**
     * Close all underlying resources
     */
    void close() @safe
    {
        foreach (k, r; managedRepos)
        {
            r.close();
        }
    }

    /**
     * Returns: dbPath specific to this project
     */
    pure @property string dbPath() @safe @nogc nothrow const
    {
        return _dbPath;
    }

    /**
     * Add a repository to this project
     *
     * Params:
     *      model = Input model
     * Returns: Nullable database error
     */
    DatabaseResult addRepository(Repository model) @safe
    {
        /* Ensure we bypass DB for quick repo lookup */
        auto lookup = (model.name in managedRepos);
        if (lookup !is null)
        {
            return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketExists,
                    "Repository already exists"));
        }

        /* Reset basic fields */
        model.id = 0;
        model.status = RepositoryStatus.Fresh;
        model.commitRef = "";

        /* Link the project */
        model.project = this._model.id;

        /* Try to store the model */
        immutable err = context.appDB.update((scope tx) => model.save(tx));
        if (!err.isNull)
        {
            return err;
        }

        /* Get it managed */
        auto managedRepository = new ManagedRepository(context, this, model);
        return managedRepository.connect.match!((Success _) {
            managedRepos[model.name] = managedRepository;
            runTask({ managedRepository.refresh(); });
            return NoDatabaseError;
        }, (Failure f) => DatabaseResult(DatabaseError(cast(DatabaseErrorCode) f.specifier,
                f.message)));
    }

    /**
     * Add a profile to this project
     *
     *      model = Input model
     * Returns: Nullable database error
     */
    DatabaseResult addProfile(Profile model) @safe
    {
        /* Do we have it */
        auto lookup = (model.name in managedProfiles);
        if (lookup !is null)
        {
            return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketExists,
                    "Profile already exists"));
        }

        /* Again, the basics */
        model.id = 0;
        model.projectID = this._model.id;

        /* Stash it */
        immutable err = context.appDB.update((scope tx) => model.save(tx));

        /* Now manage it */
        auto managed = new ManagedProfile(context, this, model);
        return managed.connect.match!((Success _) {
            managedProfiles[model.name] = managed;
            runTask({ managed.refresh(); });
            return NoDatabaseError;
        }, (Failure f) => DatabaseResult(DatabaseError(cast(DatabaseErrorCode) f.specifier,
                f.message)));
    }

package:

    /**
     * Connect via the given transaction to initialise this project
     *
     * Params:
     *      tx = read-only transaction
     * Returns: nullable database error
     */
    DatabaseResult connect(in Transaction tx) @safe
    {
        /* Load the repos */
        foreach (repo; tx.list!Repository
                .filter!((r) => r.project == model.id))
        {
            auto r = new ManagedRepository(context, this, repo);
            DatabaseResult err = r.connect.match!((Failure f) => DatabaseResult(
                    DatabaseError(cast(DatabaseErrorCode) f.specifier, f.message)),
                    (Success s) => NoDatabaseError);
            if (!err.isNull)
            {
                return err;
            }
            managedRepos[repo.name] = r;

        }

        /* Now load the profiles.. */
        foreach (profile; tx.list!Profile
                .filter!((p) => p.projectID == model.id))
        {
            auto r = new ManagedProfile(context, this, profile);
            DatabaseResult err = r.connect.match!((Failure f) => DatabaseResult(
                    DatabaseError(cast(DatabaseErrorCode) f.specifier, f.message)),
                    (Success s) => NoDatabaseError);
            if (!err.isNull)
            {
                return err;
            }
            managedProfiles[profile.name] = r;
        }
        return NoDatabaseError;
    }

private:

    ServiceContext context;
    Project _model;
    ManagedRepository[string] managedRepos;
    ManagedProfile[string] managedProfiles;
    string _dbPath;
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.context
 *
 * The manager manager.
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.projects.manager;

import moss.db.keyvalue;
import moss.db.keyvalue.errors;
import moss.db.keyvalue.orm;
import moss.service.context;
import summit.projects.project;
import summit.models.project;
import vibe.core.core : setTimer;
import vibe.d;

/**
 * The ProjectManager helps us to control the correlation between
 * the database model of projects and *usable* objects from within
 * the context of the main thread.
 */
public final class ProjectManager
{
    @disable this();

    /**
     * Construct a new ProjectManager for the given context
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /**
     * Attempt to add a new unique project to the manager
     *
     * Params:
     *      project = Unique project model
     * Returns: Nullable error
     */
    DatabaseResult addProject(Project project) @safe
    {
        /* Lets bypass db lookup where possible */
        auto lookup = (project.slug in managed);
        if (lookup !is null)
        {
            return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketExists,
                    "That project already exists"));
        }

        /* Reset .. */
        project.id = 0;

        immutable err = context.appDB.update((scope tx) => project.save(tx));
        if (!err.isNull)
        {
            return err;
        }

        /* Stash into managed table */
        auto managedProject = new ManagedProject(context, project);
        DatabaseResult helper(in Transaction tx) @safe
        {
            immutable err = managedProject.connect(tx);
            if (!err.isNull)
            {
                return err;
            }
            managed[project.slug] = managedProject;
            return NoDatabaseError;
        }

        return context.appDB.view(&helper);
    }

    /**
     * Connect with the underlying database and initialise the managed
     * instances
     *
     * Returns: Nullable error
     */
    DatabaseResult connect() @safe
    {
        DatabaseResult colLoader(in Transaction tx) @safe
        {
            foreach (model; tx.list!Project)
            {
                auto c = new ManagedProject(context, model);
                immutable err = c.connect(tx);
                if (!err.isNull)
                {
                    return err;
                }
                managed[model.slug] = c;
            }
            return NoDatabaseError;
        }

        /* Set up the model in memory */
        immutable err = context.appDB.view(&colLoader);
        if (!err.isNull)
        {
            return err;
        }

        /* Go and update the projects for the first time */
        runTask({ updateProjects(); });
        return NoDatabaseError;
    }

    /**
     * Close all underlying resources
     */
    void close() @safe
    {
        running = false;
        curTimer.stop();

        foreach (k, c; managed)
        {
            c.close();
        }
    }

    /**
     * Returns: all managed projects
     */
    pure auto @property projects() @safe nothrow
    {
        return managed.values;
    }

    /**
     * Returns: a project by slug
     *
     * Params:
     *      slug = Slug identifier
     */
    pure auto bySlug(in string slug) @safe nothrow
    {
        auto result = (slug in managed);
        return result ? *result : null;
    }

private:

    /**
     * Iterate all projects and request they update themselves, and obviously, their repos
     */
    void updateProjects() @safe
    {
        auto now = Clock.currTime();
        logInfo(format!"Updating projects at %s"(now));
        scope (exit)
        {
            runTask({
                /* Reinstall the timer */
                () @trusted { curTimer = setTimer(30.seconds, &updateProjects); }();
            });
        }

        /* Update each project */
        foreach (slug, col; managed)
        {
            logDiagnostic(format!"Requesting update check for %s"(slug));
            col.refresh();
        }
    }

    ServiceContext context;
    ManagedProject[string] managed;
    bool running;
    Timer curTimer;
}

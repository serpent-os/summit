/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.build.queue
 *
 * Core build manager + lifecycle management
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.build.queue;

public import summit.models.buildtask;
import moss.client.metadb;
import moss.deps.dependency;
import moss.deps.digraph;
import moss.deps.registry;
import moss.service.context;
import std.algorithm : canFind, each, filter, find, map;
import std.algorithm : any;
import std.range : empty, front;
import summit.models.profile;
import summit.models.project;
import summit.models.repository;
import summit.projects;
import vibe.d;

/**
 * The BuildQueue contains the logic required to form queues of
 * build jobs with interdependencies. Essentially it provides
 * first-pass capabilities, determining the relationship between
 * multiple items in a queue and yielding only those jobs with
 * no other dependencies in the queue.
 *
 * Despite the somewhat serial nature, multiple builders can be
 * allocated jobs and build them in parallel, allowing quicker
 * and more reliable repository inclusion.
 */
public final class BuildQueue
{
    @disable this();

    /**
     * Construct a new BuildQueue instance
     *
     * Params:
     *      context = global service context
     *      projectManager = Instantiated global ProjectManager
     */
    this(ServiceContext context, ProjectManager projectManager) @safe
    {
        this.context = context;
        this.projectManager = projectManager;

        /* All indices must be present on startup. */
        ensureIndicesPresent();
        loadTasks();
        checkForMissing();
        recomputeQueue();
    }

    /** 
     * Returns: All enqueued, buildable jobs with numDeps == 0 and in build order.
     */
    auto availableJobs() @safe @nogc const nothrow
    {
        return orderedQueue.filter!((j) => j.deps.empty && j.task.status == BuildTaskStatus.New);
    }

    /**
     * Returns: All enqueued jobs
     */
    auto enqueuedJobs() @safe @nogc const nothrow
    {
        return orderedQueue;
    }

    /**
     * Update the status and timestamps for the given task
     *
     * Params:
     *      taskID = Unique task identifier
     *      status = New task status
     */
    void updateTask(BuildTaskID taskID, BuildTaskStatus status) @safe
    {
        immutable err = context.appDB.update((scope tx) @safe {
            /* Ensure task exists */
            BuildTask task;
            auto err = task.load(tx, taskID);
            if (!err.isNull)
            {
                return err;
            }

            /* Update tsUpdated and maybe tsEnded */
            switch (status)
            {
            case BuildTaskStatus.Completed:
            case BuildTaskStatus.Failed:
                task.tsUpdated = Clock.currTime(UTC()).toUnixTime();
                task.tsEnded = task.tsUpdated;
                break;
            default:
                task.tsUpdated = Clock.currTime(UTC()).toUnixTime();
                break;
            }
            task.status = status;

            /* Save the model. */
            auto e = task.save(tx);
            queue[taskID] = task;
            return e;
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Resolve blocking situation */
        if (status == BuildTaskStatus.Failed)
        {
            queue.remove(taskID);
            addBlockers(taskID);
        }
        else if (status == BuildTaskStatus.Completed)
        {
            queue.remove(taskID);
            removeBlockers(taskID);
        }

        /* Rebuild queue due to some status change */
        recomputeQueue();
    }

    /**
     * Update the log URI (relative) for a build upon build completion
     */
    void setLogURI(BuildTaskID taskID, string logURI) @safe
    {
        immutable err = context.appDB.update((scope tx) @safe {
            /* Ensure task exists */
            BuildTask task;
            auto err = task.load(tx, taskID);
            if (!err.isNull)
            {
                return err;
            }
            task.logPath = logURI;
            auto e = task.save(tx);
            queue[taskID] = task;
            return e;
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    /**
     * Walk through all of the projects, fire off a check
     * for missing builds globally.
     */
    void checkForMissing() @safe
    {
        /* For all projects */
        foreach (project; projectManager.projects)
        {
            checkMissingWithinProject(project);
        }
    }

    /**
     * Check all missing jobs in repos in the project
     *
     * Params:
     *      project = Project that we believe has changed
     */
    void checkMissingWithinProject(ManagedProject project) @safe
    {
        /* For all repositories within each project */
        foreach (repo; project.repositories)
        {
            checkMissingWithinRepo(project, repo);
        }
    }

    /**
     * Find missing builds from within the given repo on all profiles
     *
     * Params:
     *      project = Parent project
     *      repo = Repository that appears to have changed
     */
    void checkMissingWithinRepo(ManagedProject project, ManagedRepository repo) @safe
    {
        auto repoModel = repo.model;
        auto projModel = project.model;

        /* And for each build target.. */
        foreach (profile; project.profiles)
        {
            auto profModel = profile.profile;
            /* For each buildable item in that repository */
            foreach (entry; repo.db.list)
            {
                foreach (name; entry.providers.filter!((p) => p.type == ProviderType.PackageName))
                {
                    auto corresponding = profile.db.byProvider(ProviderType.PackageName,
                            name.target);
                    if (corresponding.empty)
                    {
                        logDiagnostic("Missing from builds: %s/%s/%s %s-%s", project.model.slug, repo.model.name,
                                entry.name, entry.versionIdentifier, entry.sourceRelease);
                        enqueueBuildTask(projModel, repoModel, entry, profModel,
                                format!"Initial build of %s (%s-%s)"(entry.sourceID,
                                    entry.versionIdentifier, entry.sourceRelease));
                        break;
                    }
                    auto binaryEntry = profile.db.byID(corresponding.front);
                    if (binaryEntry.sourceRelease < entry.sourceRelease)
                    {
                        logDiagnostic("Out of date package %s/%s/%s (recipe: %s-%s, published: %s-%s)",
                                project.model.slug, repo.model.name, entry.name,
                                entry.versionIdentifier, entry.sourceRelease,
                                binaryEntry.versionIdentifier, binaryEntry.sourceRelease);
                        enqueueBuildTask(projModel, repoModel, entry, profModel,
                                format!"Update %s from %s-%s to %s-%s"(entry.sourceID,
                                    binaryEntry.versionIdentifier, binaryEntry.sourceRelease,
                                    entry.versionIdentifier, entry.sourceRelease));
                        break;
                    }
                }
            }
        }
    }

    /**
     * From the current job pool, determine resolveable
     * dependencies between all of the jobs and sort by
     * that ordering.
     *
     * Note that upon execution we understand our previous jobs
     * to have run to completion and the binary indices to be
     * up to date, allowing an in-depth deps analysis to happen
     * to ensure the job is possible.
     */
    void recomputeQueue() @safe
    {
        auto dag = new DirectedAcyclicalGraph!BuildTaskID;
        JobMapper[BuildTaskID] mappedEntries;
        queue.values.each!((t) => mappedEntries[t.id] = lookupTask(t));

        /* Insert all vertices first */
        mappedEntries.values.each!((m) => dag.addVertex(m.task.id));
        foreach (_, ref currentItem; mappedEntries)
        {
            /* Find commonality: All items whose publication index matches our input "remotes" */
            auto commonQueue = mappedEntries.values
                .filter!((q) => q.task.id != currentItem.task.id
                        && q.task.architecture == currentItem.task.architecture)
                .filter!((q) => currentItem.remotes.canFind!((a) => a == q.indexURI));

            /* For all of our deps, find a provider in the commonQueue to link these foreign items */
            foreach (dep; currentItem.entry.buildDependencies)
            {
                auto metDeps = commonQueue.filter!((d) => d.entry.providers.canFind!(
                        (p) => p.target == dep.target && dep.type == p.type));
                metDeps.each!((e) => dag.addEdge(currentItem.task.id, e.task.id));
            }
        }

        dag.breakCycles();
        JobMapper[] newQueue;
        try
        {
            dag.topologicalSort((d) { newQueue ~= mappedEntries[d]; });
            orderedQueue = newQueue;
        }
        catch (Exception ex)
        {
            // TODO: Mark the queue as BROKEN
            logError(format!"Build queue cannot be computed: %s"(ex.message));
        }

        /* Now install edges post cycle break */
        foreach (ref item; orderedQueue)
        {
            item.deps = dag.edges(item.task.id);
        }

        logDiagnostic(format!"Current build queue: %s"(orderedQueue.map!((o) => o.task)));
    }

private:

    /**
     * Ensure all indices for each buildable is present
     *
     * This is blocking in a fiber sense, the system continues.
     */
    void ensureIndicesPresent() @safe
    {
        foreach (project; projectManager.projects)
        {
            auto profiles = project.profiles;
            foreach (profile; profiles)
            {
                profile.refresh();
            }
        }
    }

    /**
     * Enqueue a build task.
     *
     * Right now we just re-add all tasks, without evaluating existing tasks or
     * performing any depsolving/updates. We're fleshing this iteratively.
     * 
     * Params:
     *      project = Parent project
     *      repository = Parent repository
     *      sourceEntry = Source package being updated
     *      profile = Build profile
     *      description = Description of the event for UI listing purposes
     */
    void enqueueBuildTask(Project project, Repository repository,
            MetaEntry sourceEntry, Profile profile, string description) @safe
    {
        BuildTask model;
        BuildTask existingJob;
        model.buildID = format!"%s / %s / %s-%s-%s_%s-%s"(project.slug, repository.name, sourceEntry.sourceID,
                sourceEntry.versionIdentifier, sourceEntry.sourceRelease,
                sourceEntry.buildRelease, profile.arch);

        /* Don't queue the same job again - it may have failed. */
        immutable lookupErr = context.appDB.view((in tx) => existingJob.load!"buildID"(tx,
                model.buildID));
        if (lookupErr.isNull)
        {
            return;
        }

        model.id = 0;
        model.status = BuildTaskStatus.New;
        model.slug = format!"~/%s/%s/%s"(project.slug, repository.name, sourceEntry.name);
        model.architecture = profile.arch;
        model.projectID = project.id;
        model.profileID = profile.id;
        model.description = description;
        model.repoID = repository.id;
        model.pkgID = sourceEntry.pkgID;
        model.commitRef = repository.commitRef;
        model.sourcePath = sourceEntry.sourcePath;
        model.tsStarted = Clock.currTime(UTC()).toUnixTime();
        model.tsUpdated = model.tsStarted;

        immutable err = context.appDB.update((scope tx) => model.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        logInfo(format!"New buildTask: %s"(model));
        enlivenTask(model);
    }

    /**
     * Load all tasks from the DB that need work on startup
     * This may take some time when processing all tasks.
     */
    void loadTasks() @safe
    {
        /* empty the mapping */
        queue = null;

        immutable err = context.appDB.view((scope tx) @safe {
            auto workable = tx.list!BuildTask
                .filter!((t) => t.status != BuildTaskStatus.Failed
                    && t.status != BuildTaskStatus.Completed);
            workable.each!((w) => enlivenTask(w));
            return NoDatabaseError;
        });
    }

    /**
     * Bring the DB task into the live queue for processing
     *
     * Params:
     *      task = Stale task for renewal
     */
    void enlivenTask(BuildTask task) @safe
    {
        logDiagnostic(format!"enliven: %s [%s]"(task.buildID, task.status));
        queue[task.id] = task;
    }

    /**
     * Map a build task into all usable information for queue computation
     *
     * Returns: Internal type for queue computation
     *
     * Params:
     *      task = BuildTask to lookup
     */
    JobMapper lookupTask(BuildTask task) @safe
    {
        Project project;
        Profile profile;
        Repository repo;

        /* Grab all models */
        immutable err = context.appDB.view((in tx) @safe {
            auto e = project.load(tx, task.projectID);
            if (!e.isNull)
            {
                return e;
            }
            auto e2 = profile.load(tx, task.profileID);
            if (!e2.isNull)
            {
                return e2;
            }
            return repo.load(tx, task.repoID);
        });

        if (!err.isNull)
        {
            logDiagnostic(format!"Unable to load task %s: %s"(task.buildID, err.message));
            return JobMapper.init;
        }
        /* TODO: Install the remotes PROPERLY */
        auto mProject = projectManager.bySlug(project.slug);
        auto mRepo = mProject.bySlug(repo.name);
        auto entry = mRepo.db.byID(task.pkgID);
        return JobMapper(entry, task, [profile.volatileIndexURI], profile.volatileIndexURI);
    }

    /**
     * Find all tasks depending on this one, mark them as blocked.
     */
    void addBlockers(BuildTaskID taskID) @safe
    {
        auto currentJob = orderedQueue.find!((o) => o.task.id == taskID).front;
        immutable blockID = blockerID(currentJob);

        /* Find all jobs that depend on us */
        foreach (ref job; orderedQueue.filter!((j) => j.task.id != taskID
                && j.deps.canFind!((d) => d == taskID)))
        {
            job.task.blockedBy ~= blockID;
            job.task.tsUpdated = Clock.currTime(UTC()).toUnixTime();
            job.task.status = BuildTaskStatus.Blocked;
            BuildTask model = job.task;
            immutable err = context.appDB.update((scope tx) => model.save(tx));
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

            logError(format!"[build] %s is now blocked by %s"(job.task.id, currentJob.task.id));
            queue[job.task.id] = model;
        }
    }

    /**
     * Find all tasks depending on this one, and try to unblock them
     */
    void removeBlockers(BuildTaskID taskID) @safe
    {
        import std.algorithm : remove;

        auto currentJob = orderedQueue.find!((o) => o.task.id == taskID).front;
        immutable blockID = blockerID(currentJob);

        /* Find all pool jobs that depended on us */
        foreach (ref task; queue.byValue.filter!((i) => i.status == BuildTaskStatus.Blocked
                && i.blockedBy.canFind!((i) => blockID)))
        {
            task.blockedBy = task.blockedBy.remove!((b) => b == blockID);
            task.status = task.blockedBy.empty ? BuildTaskStatus.New : BuildTaskStatus.Blocked;
            task.tsUpdated = Clock.currTime(UTC()).toUnixTime();

            immutable err = context.appDB.update((scope tx) => task.save(tx));
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

            if (task.status == BuildTaskStatus.New)
            {
                logInfo(format!"[build] Task %s now unblocked"(task.id));
            }
            else
            {
                logInfo(format!"[build] Task %s still blocked by %s"(task.id, task.blockedBy));
            }
        }
    }

    /**
     * Retrieve the unique blocker ID for a build
     */
    static auto blockerID(ref JobMapper job) @safe
    {
        return format!"%s_%s@%s/%s"(job.entry.sourceID, job.task.architecture,
                job.task.projectID, job.task.repoID);
    }

    ServiceContext context;
    ProjectManager projectManager;
    BuildTask[BuildTaskID] queue;
    JobMapper[] orderedQueue;
}

/**
 * Encapsulation of a job environment - used solely for calculating the build order.
 * Much of the information is thrown away after calculation
 */
public struct JobMapper
{
    /**
     * Source entry for this job
     */
    MetaEntry entry;

    /**
     * Real build task
     */
    BuildTask task;

    /**
     * All configured remotes
     */
    string[] remotes;

    /**
     * The publication index URI
     */
    string indexURI;

    /**
     * Tasks we depend on
     */
    BuildTaskID[] deps;
}

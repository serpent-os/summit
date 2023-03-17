/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.tasks
 *
 * Interaction with tasks
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.web.tasks;

import moss.service.context;
import moss.service.accounts;
import vibe.d;
import summit.models.buildtask;
import summit.build.queue;

/** 
 * Task enumeration and interactions
 */
@requiresAuth @path("/tasks")
public final class TasksWeb
{
    @disable this();

    mixin AppAuthenticatorContext;

    /** 
     * Create a new TasksWeb
     *
     * Params:
     *   context = global shared context
     */
    @noRoute this(ServiceContext context, BuildQueue buildQueue) @safe
    {
        this.context = context;
        this.buildQueue = buildQueue;
    }

    /** 
     * Landing page for tasks
     */
    @noAuth void index() @safe
    {
        render!"tasks/index.dt";
    }

    /** 
     * Show details on an individual task
     *
     * Params:
     *   _id = ID of the task to provide information on
     */
    @noAuth @method(HTTPMethod.GET) @path("/:id")
    void showTask(uint64_t _id) @safe
    {
        BuildTask task;
        immutable err = context.appDB.view((in tx) => task.load(tx, _id));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
        render!("tasks/view.dt", task);
    }

    /** 
     * Handle task cancellation
     *
     * Params:
     *   _id = Task to cancel
     */
    @auth(Role.notExpired & Role.web & Role.accessToken & Role.userAccount & Role.admin)
    @method(HTTPMethod.GET) @path("/:id/cancel")
    void cancelTask(uint64_t _id) @safe
    {
        BuildTask task;
        immutable err = context.appDB.view((in tx) => task.load(tx, _id));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);

        /* Set the task as failing */
        buildQueue.updateTask(_id, BuildTaskStatus.Failed);

        /* send back to the task page */
        redirect(format!"/tasks/%s"(_id));
    }

private:

    ServiceContext context;
    BuildQueue buildQueue;
}

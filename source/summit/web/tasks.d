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
    @noRoute this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /** 
     * Landing page for tasks
     */
    @noAuth void index() @safe
    {
        render!"tasks/index.dt";
    }

private:

    ServiceContext context;
}

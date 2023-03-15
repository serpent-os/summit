/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.tasks
 *
 * V1 Summit Tasks API
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.tasks;

public import summit.api.v1.interfaces;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.context;
import std.algorithm : map, sort;
import std.array : array;
import vibe.d;
import summit.models.buildtask;

/**
 * Implements the TasksService
 */
public final class TasksService : TasksAPIV1
{
    @disable this();

    /**
     * Construct new TasksService
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /**
     * Enumerate all of the tasks
     *
     * Returns: ListItem[] of all tasks
     */
    override Paginator!BuildTask enumerate(ulong pageNumber) @safe
    {
        BuildTask[] tasks;
        context.appDB.view((in tx) @safe {
            auto ret = tx.list!BuildTask;
            tasks = () @trusted { return ret.array; }();
            return NoDatabaseError;
        });
        tasks.sort!"a.id > b.id";
        return Paginator!BuildTask(tasks, pageNumber);
    }

private:

    ServiceContext context;
}

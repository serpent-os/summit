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
    override Paginator!ListItem enumerate(ulong pageNumber) @safe
    {
        ListItem[] ret;
        context.appDB.view((in tx) @safe {
            auto items = tx.list!BuildTask
                .map!((i) {
                    ListItem v;
                    v.context = ListContext.Tasks;
                    v.id = to!string(i.id);
                    v.title = i.buildID;
                    v.slug = i.slug;
                    v.subtitle = i.description;
                    return v;
                });
            ret = () @trusted { return items.array; }();
            return NoDatabaseError;
        });
        ret.sort!((a, b) => to!uint64_t(a.id) > to!uint64_t(b.id));
        return Paginator!ListItem(ret, pageNumber);
    }

private:

    ServiceContext context;
}

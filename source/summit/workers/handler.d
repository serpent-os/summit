/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.workers.handler
 *
 * Handler vtable
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.workers.handler;

public import summit.workers.messaging;
import std.exception : assumeUnique;
import vibe.d;
import std.string : format;

/* Handlers */
import summit.workers.git_handler : handleImportRepository;

/**
 * Handler function
 */
public alias HandlerFT = void function(ControlEvent event) @safe;

/**
 * Shared jump table for handlers
 */
public static immutable(HandlerFT[ControlEvent.Kind]) handlerVtable;

/**
 * Initialise the worktable
 */
shared static this()
{
    HandlerFT[ControlEvent.Kind] workerTable = [
        ControlEvent.Kind.importRepo: &handleImportRepository
    ];
    handlerVtable = assumeUnique(workerTable);
}

void processEvent(scope ref ControlEvent event) @safe
{
    auto handler = event.kind in handlerVtable;
    enforceHTTP(handler !is null, HTTPStatus.internalServerError,
            format!"No handler assigned for %s"(event.kind));
    auto rHandler = () @trusted { return *handler; }();
    rHandler(event);
}

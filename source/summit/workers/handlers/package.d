/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.workers.handlers
 *
 * Handler vtable
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.workers.handlers;

public import summit.workers.messaging;
import std.exception : assumeUnique;
import vibe.d;
import std.string : format;

/* Handlers */
import summit.workers.handlers.git : handleImportRepository;

/**
 * Handler function
 */
public alias HandlerFT = void function(scope HandlerContext context, scope const ref ControlEvent event) @safe;

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

/**
 * A HandlerContext is a safe context containing queue access
 * and system state
 */
public struct HandlerContext
{
    /**
     * The Serial Ops queue
     */
    ControlQueue serialQueue;

    /**
     * Root directory for all ops
     */
    string rootDirectory;
}

/**
 * Process event via the jump table
 *
 * Params:
 *      context = Handler context
 *      event = The event to process
 */
void processEvent(scope HandlerContext context, scope const ref ControlEvent event) @safe
{
    auto handler = event.kind in handlerVtable;
    enforceHTTP(handler !is null, HTTPStatus.internalServerError,
            format!"No handler assigned for %s"(event.kind));
    auto rHandler = () @trusted { return *handler; }();
    rHandler(context, event);
}

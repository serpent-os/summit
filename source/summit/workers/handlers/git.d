/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.workers.handlers.git
 *
 * Git support
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.workers.handlers.git;

public import summit.workers.messaging;
public import summit.workers.handlers : HandlerContext;

import vibe.d;
import vibe.core.process;
import std.path : buildPath;
import std.file : mkdirRecurse;
import std.conv : to;

/**
 * Handle a request for a repository import
 *
 * Params:
 *      context = Handling context
 *      event = the ImportRepositoryEvent
 */
public void handleImportRepository(scope HandlerContext context, scope const ref ControlEvent event) @safe
{
    auto repoEvent = cast(ImportRepositoryEvent) event;
    logInfo(format!"Importing repo: %s"(repoEvent.repo));

    auto uri = URL(repoEvent.repo.originURI);
    auto path = uri.path.toString();
    if (path.startsWith("/"))
    {
        path = path[1 .. $];
    }
    auto portion = uri.host.buildPath(path);
    auto cacheDir = context.rootDirectory.buildPath("state", "cache", "git", portion);
    cacheDir.mkdirRecurse();

    auto cmd = [
        "git", "clone", "--mirror", "--", repoEvent.repo.originURI, cacheDir,
    ];

    logDiagnostic(format!"Importing repository: %s"(cmd));
    string[string] env;
    string workDir = context.rootDirectory.buildPath("state").to!string;
    auto ret = spawnProcess(cmd, env, Config.none, NativePath(workDir));
    auto statusCode = ret.wait();

    enforceHTTP(statusCode == 0, HTTPStatus.internalServerError,
            format!"Cloning %s resulted in non-zero exit code"(repoEvent.repo));

}

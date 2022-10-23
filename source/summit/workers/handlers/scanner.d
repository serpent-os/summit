/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.workers.handlers.scanner
 *
 * Manifest/README scanning
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.workers.handlers.scanner;

public import summit.workers.messaging;
public import summit.workers.handlers : HandlerContext;

import vibe.core.process;
import vibe.d;
import std.string : format;
import std.path : buildPath, dirName;
import std.file : exists, rmdirRecurse, mkdirRecurse;

/**
 * Handle scanning for manifest.bin files
 *
 * Params:
 *      context = Handling context
 *      event = ScanManifestsEvent
 */
public void handleScanManifests(scope HandlerContext context, scope const ref ControlEvent event) @safe
{
    auto scanEvent = cast(ScanManifestsEvent) event;
    logInfo(format!"ScanManifests: %s"(scanEvent.repo));

    auto uri = URL(scanEvent.repo.originURI);
    auto path = uri.path.toString();
    if (path.startsWith("/"))
    {
        path = path[1 .. $];
    }
    auto portion = uri.host.buildPath(path);
    auto originDir = context.rootDirectory.buildPath("state", "cache", "git", portion);
    auto workDir = context.rootDirectory.buildPath("state", "work", portion);

    /* Nuke old clone */
    if (workDir.exists)
    {
        workDir.rmdirRecurse();
    }

    /* Prepare to build it again */
    workDir.dirName.mkdirRecurse();

    auto cmd = ["git", "clone", "--depth=1", originDir, workDir];
    string[string] env;

    /* Clone into new tree */
    auto ret = spawnProcess(cmd, env, Config.none,
            NativePath(context.rootDirectory.buildPath("state")));
    auto status = ret.wait();
    enforceHTTP(status == 0, HTTPStatus.internalServerError,
            format!"Failed to clone repo %s"(scanEvent.repo));

    /* Check for a README */
    /* TODO: Defer til end */
    immutable rdme = workDir.buildPath("README.md");
    if (rdme.exists)
    {
        immutable description = readFileUTF8(NativePath(rdme));
        if (description != scanEvent.repo.description)
        {
            logInfo(format!"Updating description for repository %s"(scanEvent.repo.id));
            scanEvent.repo.description = description;
            context.serialQueue.put(ControlEvent(UpdateRepositoryEvent(scanEvent.repo)));
        }
        logInfo(scanEvent.repo.description);
    }

}

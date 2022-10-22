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

import vibe.d;
import std.string : format;

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
}

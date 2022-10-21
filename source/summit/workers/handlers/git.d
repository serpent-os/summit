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
import vibe.d;

/**
 * Handle a request for a repository import
 *
 * Params:
 *      event = the ImportRepositoryEvent
 */
public void handleImportRepository(ControlEvent event) @safe
{
    auto repoEvent = cast(ImportRepositoryEvent) event;
    logInfo(format!"Importing repo: %s"(repoEvent.repo));
}

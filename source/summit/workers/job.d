/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

module summit.workers.job;

public import vibe.core.channel : Channel;

/**
 * summit.workers.job
 *
 * Base "job" types
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

public static enum taskBacklog = 100;

public alias WorkerChannel = Channel!(WorkerTask, taskBacklog);

/**
 * A scheduled task
 */
public struct WorkerTask
{
}

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.builders
 *
 * Builders Web API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.builders;

import vibe.d;

/**
 * Builder iteration
 */
@path("/builders")
public final class BuildersWeb
{
    /**
     * Builders index
     */
    void index() @safe
    {
        render!"builders/index.dt";
    }
}

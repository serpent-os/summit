/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web
 *
 * Root for all Web UI
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web;

import vibe.d;

/**
 * Web interface providing the UI experience
 */
@path("/") public final class Web
{
    /**
     * Render the home page
     */
    void index()
    {
        render!("index.dt");
    }
}

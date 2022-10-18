/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.interfaces
 *
 * V1 Summit API Interfaces
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.api.v1.interfaces;

public import vibe.d;

/**
 * Root API node
 */
@path("/api/v1")
public interface SummitAPIv1
{
    /**
     * Return the actual version identifier
     */
    @path("version") pure string versionID() @safe @nogc nothrow const;
}

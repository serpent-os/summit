/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.collections
 *
 * V1 Summit Collections API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.collections;

public import summit.api.v1.interfaces;
import vibe.d;

/**
 * Implements the CollectionsAPIv1
 */
public final class CollectionsService : CollectionsAPIv1
{
    /**
     * Enumerate all of the collections
     *
     * Returns: ListItem[] of known collections
     */
    override ListItem[] enumerate() @safe
    {
        return null;
    }
}

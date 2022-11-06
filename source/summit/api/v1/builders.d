/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.builders
 *
 * V1 Summit Builders API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.api.v1.builders;

public import summit.api.v1.interfaces;
import vibe.d;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.models.endpoints;

/**
 * Implements the BuildersService
 */
public final class BuildersService : BuildersAPIv1
{
    @disable this();

    /**
     * Construct new BuildersService
     */
    this(Database appDB) @safe
    {
        this.appDB = appDB;
    }

    /**
     * Enumerate all of the builders
     *
     * Returns: ListItem[] of known builders
     */
    override ListItem[] enumerate() @safe
    {
        ListItem[] ret;
        return ret;
    }

    /**
     * Create a new avalanche attachment
     *
     * Params:
     *      request = Incoming request
     */
    override void create(AttachAvalanche request) @safe
    {
        logDiagnostic(format!"Incoming attachment: %s"(request));
    }

private:
    Database appDB;
}

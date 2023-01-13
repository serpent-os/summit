/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.projects.remote
 *
 * Remote management
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.projects.remote;

import vibe.d;
import moss.service.context;
import summit.models;
import summit.projects.profile;

/**
 * Provides runtime encapsulation and management of remote repository
 * index files.
 */
public final class ManagedRemote
{
    @disable this();

    /**
     * Construct a new ManagedRemote
     *
     * Params:
     *      profile = The owning profile for this remote
     *      model = Backing model (already exists in the DB)
     */
    this(ServiceContext context, ManagedProfile profile, Remote model) @safe
    {
        this.context = context;
        this._model = model;
        this._profile = profile;
    }

    /**
     * Returns: Underlying model
     */
    pure @property Remote remote() @safe @nogc nothrow
    {
        return _model;
    }

    /**
     * Returns: Parent Profile
     */
    pure @property ManagedProfile profile() @safe @nogc nothrow
    {
        return _profile;
    }

private:

    Remote _model;
    ServiceContext context;
    ManagedProfile _profile;
}

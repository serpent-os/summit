/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.setup
 *
 * Web-based setup application
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.setup;

import vibe.d;
import vibe.core.channel;

/**
 * SetupApplication is only constructed when we actually
 * need first run configuration
 */
public final class SetupApplication
{
    @disable this();

    /**
     * Construct a new SetupApplication
     */
    this(Channel!(bool, 1) notifier) @safe
    {
        this.notifier = notifier;
        _router = new URLRouter();
        _router.registerWebInterface(this);
    }

    /**
     * / redirects to make our intent obvious
     */
    void index() @safe
    {
        immutable path = request.path.endsWith("/") ? request.path[0 .. $ - 1] : request.path;
        redirect(format!"%s/setup"(path));
    }

    /**
     * Real index page
     */
    @path("setup") @method(HTTPMethod.GET)
    void setupIndex() @safe
    {
        render!"setup/index.dt";
    }

    /**
     * Returns: the underlying URLRouter
     */
    @noRoute pragma(inline, true) pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

private:

    URLRouter _router;
    Channel!(bool, 1) notifier;
}

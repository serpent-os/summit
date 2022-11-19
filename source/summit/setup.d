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
import vibe.web.validation;

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
     * Attempt to apply setup.
     *
     * Params:
     *      instanceURI = Our public instance URI
     *      description = Friendly description for our instance
     *      username = Administrator username
     *      emailAddress = Admin email
     *      password = Admin password
     *      confirmPassword = Confirmation that password matches
     */
    @path("setup/apply") @method(HTTPMethod.POST) void applySetup(string instanceURI,
            string description, ValidUsername username,
            ValidEmail emailAddress, ValidPassword password, Confirm!"password" confirmPassword) @sanitizeUTF8
    {
        /* Unlock instance */
        scope (success)
        {
            notifier.put(true);
            redirect("/");
        }
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

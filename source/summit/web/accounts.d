/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.accounts;
 *
 * The accounts web UI
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.accounts;

import vibe.d;

/**
 * Web interface providing the UI experience
 */
@path("accounts") public final class AccountsWeb
{

    /**
     * Provide the basic registration form
     */
    @path("register") @method(HTTPMethod.GET) void register() @safe
    {
        render!"accounts/register.dt";
    }

    /**
     * Provide the login form
     */
    @path("login") @method(HTTPMethod.GET) void login() @safe
    {
        render!"accounts/login.dt";
    }
}

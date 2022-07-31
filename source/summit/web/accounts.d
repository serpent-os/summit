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
import summit.accounts;

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

    /**
     * Attempt to perform the actual login
     * This will be dispatched via the AccountsManager
     *
     * Params:
     *      username = Account ID to login with
     *      password = The account plaintext password.
     */
    @path("login") @method(HTTPMethod.POST) void loginUser(ref ValidUsername username,
            ref ValidPassword password) @safe
    {
        auto pw = password.toString;
        lockString(pw);
        scope (exit)
        {
            unlockString(pw);
        }
    }

    /**
     * Attempt registration of the user
     * We rely on client-side form validation and require valid username, password + email address.
     *
     * Params:
     *      username = New username
     *      password = New password
     *      confirmPassword = Ensure passwords match
     *      email = Users email address (validation)
     *      policy = Must be true to accept privacy policy
     */
    @path("register") @method(HTTPMethod.POST) void registerUser(ValidUsername username,
            ref ValidPassword password, ref Confirm!"password" confirmPassword,
            ValidEmail email, bool policy) @safe
    {
        auto pw = password.toString;
        auto pw2 = confirmPassword.toString;
        lockString(pw);
        lockString(pw2);
        scope (exit)
        {
            unlockString(pw);
            unlockString(pw2);
        }
    }
}

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
 * We know we're logged in when WebSession says so.
 * These methods are safe to use from templates,
 * however do NOT use from the REST API.
 *
 * Basically it just has a loggedIn var + a token.
 */
public struct WebSession
{
    /**
     * Are we logged in?
     */
    SessionVar!(bool, "loggedIn") loggedIn;

    /** 
     * Allows access to some REST APIs.
     */
    SessionVar!(string, "accessToken") accessToken;
}

/**
 * Web interface providing the UI experience
 */
@path("accounts") public final class AccountsWeb
{

    /**
     * Configure this module for account management
     */
    @noRoute void configure(URLRouter root, AccountManager accountManager) @safe
    {
        root.registerWebInterface(this);
        this.accountManager = accountManager;
    }

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
     *      emailAddress = Users email address (validation)
     *      policy = Must be true to accept privacy policy
     */
    @path("register") @method(HTTPMethod.POST) void registerUser(ValidUsername username, ref ValidPassword password,
            ref Confirm!"password" confirmPassword, ValidEmail emailAddress, bool policy) @safe
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

    /**
     * End the current session
     * TODO: Revoke session tokens
     */
    @path("logout") @method(HTTPMethod.GET) void logout() @safe
    {
        terminateSession();
        redirect("/");
    }

private:

    AccountManager accountManager;
}

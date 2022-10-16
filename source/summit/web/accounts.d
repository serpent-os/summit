/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.accounts
 *
 * Account management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.accounts;

import vibe.d;
import moss.service.accounts;

/**
 * Allow views to access session information
 * DO NOT use outside of WebInterface APIs
 */
public struct WebSession
{
    /**
     * Set true if we're logged in
     */
    SessionVar!(bool, "activeSession") loggedIn;
}

/**
 * Root entry into our web service
 */
@path("/accounts") public final class AccountsWeb
{
    @disable this();

    /**
     * Construct new AccountsWeb
     *
     * Params:
     *      accountManager = Account management
     */
    this(AccountManager accountManager) @safe
    {
        this.accountManager = accountManager;
    }

    /**
     * Install account management into web app
     *
     * Params:
     *      router = Root namespace
     */
    @noRoute void configure(URLRouter router) @safe
    {
        router.registerWebInterface(this);
    }

    /**
     * Render the login form
     */
    @method(HTTPMethod.GET) @path("login") void renderLogin() @safe
    {
        render!"accounts/login.dt";
    }

    /**
     * Render the registration form
     */
    @method(HTTPMethod.GET) @path("register") void renderRegistration() @safe
    {
        render!"accounts/register.dt";
    }

private:
    AccountManager accountManager;
}

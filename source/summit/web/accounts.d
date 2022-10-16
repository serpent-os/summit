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
import vibe.web.validation;

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
     * Perform the login
     *
     * Params:
     *      username = Valid username
     *      password = Valid password
     */
    @method(HTTPMethod.POST) @path("login") void handleLogin(ValidUsername username,
            ValidPassword password) @safe
    {
        accountManager.authenticateUser(username, password).match!((User user) {
            logInfo(format!"User successfully logged in: %s [%s]"(user.username, user.id));
            startSession();
        }, (DatabaseError e) {
            logError(format!"Failed login for user '%s': %s"(username, e));
            endSession();
            throw new HTTPStatusException(HTTPStatus.forbidden, e.message);
        });
        redirect("/");
    }

    /**
     * Render the registration form
     */
    @method(HTTPMethod.GET) @path("register") void renderRegistration() @safe
    {
        render!"accounts/register.dt";
    }

    /**
     * Register a new user
     *
     * Params:
     *      username = New username
     *      emailAddress = Valid email address
     *      password = New password
     *      confirmPassword = Validate password
     *      policy = Ensure policy is accepted
     */
    @method(HTTPMethod.POST) @path("register") void handleRegistration(ValidUsername username,
            ValidEmail emailAddress, ValidPassword password,
            Confirm!"password" confirmPassword, bool policy) @safe
    {
        scope (exit)
        {
            redirect("/");
        }
        scope (failure)
        {
            endSession();
        }
        enforceHTTP(policy, HTTPStatus.forbidden, "Policy must be accepted");
        immutable err = accountManager.registerUser(username, password);
        enforceHTTP(err.isNull, HTTPStatus.forbidden, err.message);
        startSession();
    }

private:

    /**
     * Start a login session
     */
    void startSession() @safe
    {
        auto session = WebSession();
        session.loggedIn = true;
    }

    /**
     * End the session
     */
    void endSession() @safe
    {
        auto session = WebSession();
        session.loggedIn = false;
        terminateSession();
    }

    AccountManager accountManager;
}

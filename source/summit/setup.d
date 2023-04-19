/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.setup
 *
 * Web-based setup application
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.setup;

import moss.service.context;
import moss.service.server;
import summit.models;
import vibe.d;
import vibe.web.validation;

/**
 * SetupApplication is only constructed when we actually
 * need first run configuration
 */
public final class SetupApplication : Application
{
    override void initialize(ServiceContext context) @safe
    {
        this.context = context;
        _router = new URLRouter();
        _router.registerWebInterface(this);
    }

    override void close() @safe
    {
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
    void setupIndex(FormError _error = FormError.init, string instanceURI = null,
            string description = null, string username = null, string emailAddress = null) @safe
    {
        /* Throw internal error if not from field validation */
        if (!_error.error.empty && _error.field.empty)
        {
            throw new HTTPStatusException(HTTPStatus.internalServerError, _error.error);

        }

        render!("setup/index.dt", _error, instanceURI, description, username, emailAddress);
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
    @path("setup") @method(HTTPMethod.POST) @errorDisplay!setupIndex void applySetup(
            string instanceURI, string description,
            ValidUsername username,
            ValidEmail emailAddress, ValidPassword password, Confirm!"password" confirmPassword) @sanitizeUTF8
    {
        Settings appSettings;

        /* Try to get our settings */
        getSettings(context.appDB).match!((Settings s) { appSettings = s; }, (DatabaseError err) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, err.message);
        });

        /* Basic settings */
        appSettings.instanceDescription = description;
        appSettings.instanceURI = instanceURI;
        appSettings.setupComplete = true;

        /*  Add admin account :) */
        context.accountManager.registerUser(username, password, emailAddress).match!((Account acct) {
            immutable err = context.accountManager.addAccountToGroups(acct.id,
                [BuiltinGroups.Admin, BuiltinGroups.Users]);
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        }, (DatabaseError err) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, err.message);
        });

        /* Now save the settings! */
        immutable err = context.appDB.update((scope tx) => appSettings.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Done! */
        completed.emit;
        redirect("/");
    }

    /**
     * Returns: the underlying URLRouter
     */
    @noRoute override pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

private:

    URLRouter _router;
    ServiceContext context;
}

private struct FormError
{
    string error;
    string field;
}

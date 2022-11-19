/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.context
 *
 * Contextual storage - DBs, etc.
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.context;

public import moss.db.keyvalue;
public import moss.service.accounts;
public import moss.service.tokens.manager;
import moss.service.models;
import std.file : mkdirRecurse;
import std.path : buildPath;
import summit.models;
import vibe.d;

/**
 * Shared databases, etc.
 */
public final class SummitContext
{
    @disable this();

    /**
     * Construct new context with the given root directory
     */
    this(string rootDirectory) @safe
    {
        this._rootDirectory = rootDirectory;
        immutable statePath = rootDirectory.buildPath("state");
        this._dbPath = statePath.buildPath("db");
        dbPath.mkdirRecurse();

        /* Get token manager up and running */
        _tokenManager = new TokenManager(statePath);
        logInfo(format!"Instance pubkey: %s"(tokenManager.publicKey));

        /* open our DB */
        Database.open(format!"lmdb://%s"(dbPath.buildPath("app")),
                DatabaseFlags.CreateIfNotExists).tryMatch!((Database db) {
            _appDB = db;
        });

        /* Configure the model */
        immutable dbErr = appDB.update((scope tx) => tx.createModel!(PackageCollection,
                Repository, AvalancheEndpoint, Settings));
        enforceHTTP(dbErr.isNull, HTTPStatus.internalServerError, dbErr.message);

        /* Establish account management */
        _accountManager = new AccountManager(dbPath.buildPath("accounts"));
    }

    /**
     * Release all resources
     */
    void close() @safe
    {
        _accountManager.close();
        _appDB.close();
    }

    /**
     * Returns: The current tokenManager
     */
    pragma(inline, true) pure @property TokenManager tokenManager() @safe @nogc nothrow
    {
        return _tokenManager;
    }

    /**
     * Returns: the account manager
     */
    pragma(inline, true) pure @property AccountManager accountManager() @safe @nogc nothrow
    {
        return _accountManager;
    }

    /**
     * Returns: the application database
     */
    pragma(inline, true) pure @property Database appDB() @safe @nogc nothrow
    {
        return _appDB;
    }

    /**
     * Returns: root directory
     */
    pragma(inline, true) pure @property string rootDirectory() @safe @nogc nothrow const
    {
        return _rootDirectory;
    }

    /**
     * Returns: the database path
     */
    pragma(inline, true) pure @property string dbPath() @safe @nogc nothrow const
    {
        return _dbPath;
    }

private:

    TokenManager _tokenManager;
    AccountManager _accountManager;
    Database _appDB;

    string _rootDirectory;
    string _dbPath;
}

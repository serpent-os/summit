/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.accounts
 *
 * Account management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.accounts;

import libsodium;
import moss.db.keyvalue;
import moss.db.keyvalue.errors;
import moss.db.keyvalue.interfaces;
import moss.db.keyvalue.orm;
import summit.models.group;
import summit.models.token;
import summit.models.user;
import vibe.d;

/**
 * Attempt to determine authentication from the current web context
 *
 * Note this is not the same thing as authorisation, that is handled
 * by tokens and permissions.
 */
public struct SummitAuthentication
{
    /**
     * Construct a SummitAuthenticaiton helper from the given
     * HTTP connection
     * To make use of this, simply construct and return the type from
     * your APIs authenticate(req, res) method and it will do the rest.
     */
    this(scope return AccountManager accountManager, scope HTTPServerRequest req,
            scope HTTPServerResponse res) @safe
    {
        throw new HTTPStatusException(HTTPStatus.forbidden, "no permissions implemented sorry");
    }

    /**
     * Remote access tokens - sessions are invalid.
     *
     * Returns: true if using a remote access token
     */
    pure bool isRemoteAccess() @safe @nogc nothrow
    {
        return false;
    }
}

/**
 * Generate boilerplate needed to get authentication working
 *
 * You will need an accountManager instance available.
 */
mixin template AppAuthenticator()
{
    @noRoute public SummitAuthentication authenticate(scope HTTPServerRequest req,
            scope HTTPServerResponse res) @safe
    {
        return SummitAuthentication(accountManager, req, res);
    }
}

/**
 * The AccountManager hosts all account management within
 * its own DB tree.
 */
public final class AccountManager
{
    @disable this();

    /**
     * Construct a new AccountManager from the given path
     */
    this(string dbPath) @safe
    {
        /* Enforce the creation */
        userDB = Database.open(dbPath, DatabaseFlags.CreateIfNotExists)
            .tryMatch!((Database db) => db);

        /* Ensure model exists */
        auto err = userDB.update((scope tx) => tx.createModel!(User, Group, Token));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    /**
     * Attempt to register the user.
     *
     * Params:
     *      username = New user identifier
     *      password = New password
     * Returns: Nullable database error
     */
    DatabaseResult registerUser(string username, string password) @safe
    {
        /* Make sure nobody exists wit that username. */
        {
            User lookupUser;
            immutable err = userDB.view((in tx) => lookupUser.load!"username"(tx, username));
            if (err.isNull)
            {
                return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketExists,
                        "User already exists"));
            }
        }

        /* Register the new user */
        auto user = User();
        user.hashedPassword = generateSodiumHash(password);
        user.username = username;
        user.type = UserType.Standard;
        return userDB.update((scope tx) => user.save(tx));
    }

    /**
     * Check if authentication works via the DB
     *
     * To prevent brute force we'll never admit if a username exists.
     *
     * Params:
     *      username = Registered username
     *      password = Registered password
     * Returns: Nullable database error
     */
    SumType!(User, DatabaseError) authenticateUser(string username, string password) @safe
    {
        User lookup;
        static auto noUser = DatabaseResult(DatabaseError(DatabaseErrorCode.BucketNotFound,
                "Username or password incorrect"));

        immutable err = userDB.view((in tx) @safe {
            /* Check if the user exists first :) */
            immutable err = lookup.load!"username"(tx, username);
            if (!err.isNull)
            {
                return noUser;
            }
            /* Check the password is right */
            if (!sodiumHashMatch(lookup.hashedPassword, password))
            {
                return noUser;
            }
            return NoDatabaseError;
        });
        /* You can haz User now */
        if (err.isNull)
        {
            /* No hash for u */
            lookup.hashedPassword = null;
            return SumType!(User, DatabaseError)(lookup);
        }
        return SumType!(User, DatabaseError)(err);
    }

private:

    Database userDB;
}

/**
 * Generate sodium hash from input
 */
static private string generateSodiumHash(in string password) @safe
{
    char[crypto_pwhash_STRBYTES] ret;
    auto inpBuffer = password.toStringz;
    int rc = () @trusted {
        return crypto_pwhash_str(ret, cast(char*) inpBuffer, password.length,
                crypto_pwhash_OPSLIMIT_INTERACTIVE, crypto_pwhash_MEMLIMIT_INTERACTIVE);
    }();

    if (rc != 0)
    {
        return null;
    }
    return ret.fromStringz.dup;
}

/**
 * Verify a password matches the given stored hash
 */
static private bool sodiumHashMatch(in string hash, in string userPassword) @safe
in
{
    assert(hash.length <= crypto_pwhash_STRBYTES);
}
do
{
    return () @trusted {
        char[crypto_pwhash_STRBYTES] buf;
        auto pwPtr = hash.toStringz;
        auto userPtr = userPassword.toStringz;
        buf[0 .. hash.length + 1] = pwPtr[0 .. hash.length + 1];

        return crypto_pwhash_str_verify(buf, userPtr, userPassword.length);
    }() == 0;
}

/**
 * Lock a region of memory
 *
 * Params:
 *      inp = Region of memory to lock
 */
public static void lockString(ref string inp) @safe
{
    () @trusted {
        auto rc = sodium_mlock(cast(void*) inp.ptr, inp.length);
        enforceHTTP(rc == 0, HTTPStatus.internalServerError, "Failed to sodium_mlock string");
    }();
}

/**
 * Unlock and zero memory
 *
 * Params:
 *      inp = Region of memory to unlock
 */
public static void unlockString(ref string inp) @safe
{
    () @trusted {
        auto rc = sodium_munlock(cast(void*) inp.ptr, inp.length);
        enforceHTTP(rc == 0, HTTPStatus.internalServerError, "Failed to sodium_munlock string");
    }();
}

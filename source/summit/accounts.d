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

import summit.models.group;
import summit.models.token;
import summit.models.user;

import moss.db.keyvalue;
import moss.db.keyvalue.errors;
import moss.db.keyvalue.interfaces;
import moss.db.keyvalue.orm;

import vibe.d;

import libsodium;

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

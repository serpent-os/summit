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

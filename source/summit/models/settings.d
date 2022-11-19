/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.settings
 *
 * Model for settings storage
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.models.settings;

import moss.db.keyvalue;
import moss.db.keyvalue.orm;

/**
 * We abuse models to create one-time settings objects
 */
public @Model struct Settings
{
    /**
     * Force single-instance Settins
     */
    @PrimaryKey int id = 0;

    /**
     * Setup is incomplete at first
     */
    bool setupComplete;

    /**
     * What is our public instance URI?
     */
    string instanceURI = "";

    /**
     * Instance description, useful for pairing
     */
    string instanceDescription;
}

/**
 * Try to grab the settings (existing or fresh)
 *
 * Params:
 *      appDB = Application database
 * Returns: Settings, or database error
 */
public SumType!(Settings, DatabaseError) getSettings(Database appDB) @safe
{
    Settings stored;

    immutable err = appDB.view((in tx) => stored.load(tx, stored.id));
    if (!err.isNull && err.code == DatabaseErrorCode.BucketNotFound)
    {
        return SumType!(Settings, DatabaseError)(Settings.init);
    }

    return err.isNull ? SumType!(Settings,
            DatabaseError)(stored) : SumType!(Settings, DatabaseError)(err);
}

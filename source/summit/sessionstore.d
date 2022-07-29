/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.sessionstore
 *
 * Persistent session storage
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.sessionstore;

import vibe.d;
import moss.db.keyvalue;
import moss.db.keyvalue.interfaces;
import std.algorithm : map;
import std.array : array;

/**
 * Encapsulate BSON serialisation within moss-db
 */
public struct BsonRecord
{
    /**
     * Stored type of the record
     */
    Bson.Type type;

    /**
     * Stored raw data of the record
     */
    ubyte[] data;

    /**
     * Copy a Bson for input
     */
    this(Bson input) @safe
    {
        type = input.type;
        data = input.data.dup;
    }

    /**
     * Convert to vibe.d Bson type
     *
     * Returns: A Bson struct
     */
    Bson bson() @safe const
    {
        return () @trusted { return Bson(type, cast(immutable(ubyte[])) data); }();
    }

    /**
     * Convert to moss encoded data
     *
     * Returns: Encoded data
     */
    ImmutableDatum mossEncode() @safe const
    {
        return () @trusted { return cast(ImmutableDatum)(type.mossEncode ~ data); }();
    }

    /**
     * Decode the stream into a bson sequence
     *
     * Params:
     *      rawBytes = Input sequence
     */
    void mossDecode(in ImmutableDatum rawBytes) @safe
    {
        enforceHTTP(rawBytes.length > Bson.Type.sizeof,
                HTTPStatus.internalServerError, "BsonRecord: Cannot decode null bytes");
        auto typeSeq = rawBytes[0 .. Bson.Type.sizeof];
        immutable remainder = rawBytes[Bson.Type.sizeof .. $];
        type.mossDecode(typeSeq);
        data = remainder.dup;
    }
}

/**
 * Session storage using moss-db!
 */
public final class DBSessionStore : SessionStore
{
    @disable this();

    /**
     * Create a new DB backed session store using a moss-db
     * appropriate URI, i.e. lmdb:// ...
     */
    this(string dbPath) @safe
    {
        db = Database.open(dbPath, DatabaseFlags.CreateIfNotExists).tryMatch!((Database d) => d);
    }

    ~this()
    {
        db.close();
    }

    /**
     * For simplicity we store all keys as serialised Bson to vastly
     * simplify requirements.
     * 
     * Returns: SessionStorageType.bson
     */
    override pure @property SessionStorageType storageType() @safe const
    {
        return SessionStorageType.bson;
    }

    /**
     * Create a new session
     *
     * Returns: A Session instance
     */
    override Session create() @safe
    {
        auto session = createSessionInstance();
        auto err = db.update((scope tx) @safe {
            /* Create a new bucket */
            return tx.createBucket(session.id)
                .match!((DatabaseError err) => DatabaseResult(err), (Bucket bk) => NoDatabaseError);
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        return session;
    }

    /**
     * Open an existing session
     *
     * Params:
     *      id = Unique session identifier
     * Returns: A Session instance
     */
    override Session open(string id) @safe
    {
        auto session = createSessionInstance(id);
        auto err = db.view((scope tx) @safe {
            return tx.bucket(id).isNull ? DatabaseResult(DatabaseError(DatabaseErrorCode.BucketNotFound,
                "Session.open(): Invalid session " ~ id)) : NoDatabaseError;
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        return session;
    }

    /**
     * We encode everything as BSON in our internal storage to make
     * things simpler.
     *
     * Params:
     *      id = Session ID
     *      name = Key name
     *      value = Key value
     */
    override void set(string id, string name, Variant value) @safe
    {
        Bson realValue = () @trusted { return value.get!Bson; }();

        /* Store it.. */
        auto err = db.update((scope tx) @safe {
            auto bucket = tx.bucket(id);
            if (bucket.isNull)
            {
                return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketNotFound,
                    "Session.set(): Invalid session: " ~ id));
            }
            return tx.set(bucket, name, BsonRecord(realValue));
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    /**
     * Retrieve the (Bson) value from the store, or the default Value
     *
     * Params:
     *      id = Session ID
     *      name = Key name
     *      defaultValue = Fallback value
     * Returns: Either the discovered or default value
     */
    override Variant get(string id, string name, lazy Variant defaultValue) @safe
    {
        Bson ret;
        auto err = db.view((in tx) @safe {
            auto bucket = tx.bucket(id);
            if (bucket.isNull)
            {
                return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketNotFound,
                    "Session.get(): Invalid session: " ~ id));
            }
            auto bytes = tx.get(bucket, name.mossEncode);
            BsonRecord stored;

            /* Nothing here bud */
            if (bytes is null)
            {
                ret = () @trusted { return defaultValue.get!Bson; }();
                return NoDatabaseError;
            }
            stored.mossDecode(bytes);
            ret = stored.bson();
            return NoDatabaseError;
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        return () @trusted { return Variant(ret); }();
    }

    /**
     * Determine if a key exists within a session 
     *
     * Params:
     *      id = Session ID
     *      key = Key name
     * Returns: True if the key is set
     */
    override bool isKeySet(string id, string key) @safe
    {
        bool haveKey;
        db.view((in tx) @safe {
            auto bucket = tx.bucket(id);
            haveKey = !bucket.isNull ? tx.get(bucket, key.mossEncode) !is null : false;
            return NoDatabaseError;
        });
        return haveKey;
    }

    /**
     * Remove a key from the session
     *
     * Params:
     *      id = Session ID
     *      key = Key name
     */
    override void remove(string id, string key) @safe
    {
        auto err = db.update((scope tx) @safe {
            auto bucket = tx.bucket(id);
            if (bucket.isNull)
            {
                return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketNotFound,
                    "Session.remove(): Invalid session: " ~ id));
            }
            return tx.remove(bucket, key.mossEncode);
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    /**
     * Destroy a session completely
     *
     * Params:
     *      id = Session ID
     */
    override void destroy(string id) @safe
    {
        auto err = db.update((scope tx) @safe {
            auto bucket = tx.bucket(id);
            if (bucket.isNull)
            {
                return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketNotFound,
                    "Session.destroy(): Invalid session: " ~ id));
            }
            return tx.removeBucket(bucket);
        });
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    /**
     * Iterate the session keys
     *
     * Note: This deliberately uses some copying to avoid recursive transactions
     * from idiotic use by me.
     *
     * Params:
     *      id = Session ID
     *      del = a foreach-style delegate
     * Returns: The return value for foreach-ing
     */
    int iterateSession(string id, scope int delegate(string key) @safe del) @safe
    {
        string[] keys;
        db.view((in tx) @safe {
            auto bucket = tx.bucket(id);
            if (bucket.isNull)
            {
                return DatabaseResult(DatabaseError(DatabaseErrorCode.BucketNotFound,
                    "Session.iterateSession(): Invalid session: " ~ id));
            }
            keys = tx.iterator!(string, BsonRecord)(bucket).map!((tup) => tup.key).array();
            return NoDatabaseError;
        });

        foreach (key; keys)
        {
            auto ret = del(key);
            if (ret)
            {
                return ret;
            }
        }
        return 0;
    }

private:

    Database db;
}

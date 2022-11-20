/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.api.v1.pairing
 *
 * Implementation of service enrolment
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.api.v1.pairing;

public import moss.service.interfaces;

import vibe.d;
import moss.service.accounts;
import moss.service.accounts.auth;
import moss.service.tokens;
import moss.service.tokens.manager;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;

/**
 * Implementation of the hub-aspect enrolment API
 */
public final class PairingService : ServiceEnrolmentAPI
{
    @disable this();

    mixin AppAuthenticator;

    /** 
     * Construct new pairing API
     */
    this(TokenManager tokenManager, AccountManager accountManager, Database appDB) @safe
    {
        this.tokenManager = tokenManager;
        this.accountManager = accountManager;
        this.appDB = appDB;
    }

    override void enrol(ServiceEnrolmentRequest request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "Summit does not support .enrol()");
    }

    override string refreshToken(NullableToken token) @safe
    {
        return "";
    }

    override string refreshIssueToken(NullableToken token) @safe
    {
        return "";
    }

    override void accept(ServiceEnrolmentRequest request, NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "accept(): Not yet implemented");
    }

    override void decline(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "decline(): Not yet implemented");
    }

    override void leave(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "leave(): Not yet implemented");
    }

    /**
     * TODO: Replace builder enumeration code?
     */
    override VisibleEndpoint[] enumerate() @safe
    {
        return null;
    }

private:

    TokenManager tokenManager;
    AccountManager accountManager;
    Database appDB;
}

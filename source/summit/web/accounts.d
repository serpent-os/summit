/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.accounts
 *
 * Account management
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.web.accounts;

import moss.service.context;
import vibe.d;

/**
 * Basic subclass to support local rendering
 */
@path("/accounts") public final class SummitAccountsWeb : AccountsWeb
{
    @disable this();

    /**
     * Construct new accounts web
     */
    this(ServiceContext context) @safe
    {
        super(context.accountManager, context.tokenManager, "summit");
        this.context = context;
    }

    override void renderLogin() @safe
    {
        render!"accounts/login.dt";
    }

    override void renderRegister() @safe
    {
        enforceHTTP(context.accountManager.userRegistrationsAllowed,
                HTTPStatus.forbidden, "User registration not permitted");
        render!"accounts/register.dt";
    }

private:

    ServiceContext context;
}

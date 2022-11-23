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
import summit.context;

/**
 * Basic subclass to support local rendering
 */
@path("/accounts") public final class SummitAccountsWeb : AccountsWeb
{
    @disable this();

    /**
     * Construct new accounts web
     */
    this(SummitContext context) @safe
    {
        super(context.accountManager, context.tokenManager, "summit");
    }

    override void renderLogin() @safe
    {
        render!"accounts/login.dt";
    }

    override void renderRegister() @safe
    {
        render!"accounts/register.dt";
    }
}

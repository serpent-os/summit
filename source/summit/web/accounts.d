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
import moss.service.accounts;
import moss.service.tokens.manager;

/**
 * Basic subclass to support local rendering
 */
public final class SummitAccountsWeb : AccountsWeb
{
    @disable this();

    /**
     * Construc new accounts web
     */
    this(AccountManager accountManager, TokenManager tokenManager) @safe
    {
        super(accountManager, tokenManager);
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

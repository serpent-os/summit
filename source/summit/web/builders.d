/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.builders
 *
 * Interaction with builders
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.web.builders;

import moss.service.context;
import moss.service.accounts;
import vibe.d;

/** 
 * BuilderWeb management
 */
@requiresAuth @path("/builders") public final class BuilderWeb
{
    @disable this();

    mixin AppAuthenticatorContext;

    /** 
     * Construct new BuilderWeb
     *
     * Params:
     *   context = global shared context
     */
    @noRoute this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /** 
     * Landing page for builders, rendered mostly with JS
     */
    @noAuth void index() @safe
    {
        render!"builders/index.dt";
    }

private:

    ServiceContext context;
}

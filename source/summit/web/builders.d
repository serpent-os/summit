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
import moss.service.models.endpoints;

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

    /**
     * View an avalanche endpoint.
     *
     * Params:
     *   _id = Identifier for the AvalancheEndpoint
     */
    @noAuth @method(HTTPMethod.GET) @path("/:id") void viewBuilder(string _id) @safe
    {
        AvalancheEndpoint endpoint;
        immutable err = context.appDB.view((in tx) => endpoint.load(tx, _id));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
        render!("builders/view.dt", endpoint);
    }

    /**
     * Delete a builder completely (account, endpoint + tokens)
     *
     * Params:
     *   _id = Identifier for the AvalancheEndpoint
     */
    @auth(Role.notExpired & Role.web & Role.accessToken & Role.userAccount & Role.admin)
    @method(HTTPMethod.GET) @path("/:id/delete")
    void deleteBuilder(string _id) @safe
    {
        /* Make sure its alive */
        AvalancheEndpoint endpoint;
        immutable err = context.appDB.view((in tx) => endpoint.load(tx, _id));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);

        logWarn(format!"Deleting endpoint: %s"(_id));
        auto serviceAccount = endpoint.serviceAccount;

        /* Remove the endpoint */
        immutable e = context.appDB.update((scope tx) => endpoint.remove(tx));
        enforceHTTP(e.isNull, HTTPStatus.internalServerError, err.message);

        immutable e2 = context.accountManager.removeAccount(serviceAccount);
        enforceHTTP(e2.isNull, HTTPStatus.internalServerError, e2.message);

        /* Back to the builders view */
        redirect("/builders");
    }

    /**
     * Try to repair the builder.
     *
     * At the moment this simply marks it operational again, and subsequent builds may
     * then cause it to fail.
     *
     * Params:
     *   _id = unique builder ID
     */
    @auth(Role.notExpired & Role.web & Role.accessToken & Role.userAccount & Role.admin)
    @method(HTTPMethod.GET) @path("/:id/repair")
    void repairBuilder(string _id) @safe
    {
        /* Make sure its alive */
        AvalancheEndpoint endpoint;
        immutable err = context.appDB.view((in tx) => endpoint.load(tx, _id));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);

        endpoint.status = EndpointStatus.Operational;
        endpoint.statusText = "Fully operational";
        endpoint.workStatus = WorkStatus.Idle;
        immutable svErr = context.appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(svErr.isNull, HTTPStatus.internalServerError, err.message);

        redirect("/builders");
    }

private:

    ServiceContext context;
}

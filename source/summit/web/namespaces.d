/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.web.namespaces;
 *
 * The projects web UI
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.web.namespaces;

import vibe.d;
import std.typecons : Nullable;
import summit.models.namespace;
import moss.db.keyvalue;
import moss.db.keyvalue.interfaces;
import moss.db.keyvalue.errors;
import moss.db.keyvalue.orm;

/**
 * Web interface providing the UI experience
 */
@path("~") public final class NamespacesWeb
{

    /**
     * Configure this router for use
     */
    @noRoute void configure(URLRouter root, Database appDB) @safe
    {
        root.registerWebInterface(this);
        this.appDB = appDB;
    }

    /**
     * Render the landing page
     */
    @method(HTTPMethod.GET)
    void index() @safe
    {
        render!("namespaces/index.dt");
    }

    /**
     * View a single namespace
     *
     * Params:
     *      _path = The path portion to render
     */
    @path("/:path") @method(HTTPMethod.GET)
    void view(string _path) @safe
    {
        Namespace namespace;
        auto err = appDB.view((in tx) => namespace.load!"slug"(tx, _path));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
        render!("namespaces/view.dt", namespace);
    }

    @path("/:path/:project") @method(HTTPMethod.GET)
    void viewProject(string _path, string _project) @safe
    {
        render!("namespaces/index.dt", _path, _project);
    }

    @path("/:path/:project/:package") @method(HTTPMethod.GET)
    void viewPackage(string _path, string _project, string _package)
    {
        render!("namespaces/index.dt", _path, _project, _package);

    }

private:

    Database appDB;
}

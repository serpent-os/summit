/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.rest.namespaces
 *
 * API for Namespace management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module summit.rest.namespaces;

import vibe.d;

import summit.models.namespace;
import summit.models.project;
import moss.db.keyvalue;
import std.array : array;
import std.algorithm : map;

/**
 * A premapped renderable namespace with projects.
 */
public struct RenderNamespaceItem
{
    /**
     * Real Namespace model
     */
    Namespace ns;

    /**
     * Preloaded projects
     */
    Project[] projects;
}

/**
 * The Namespaces API
 */
@path("api/v1/namespaces") public interface NamespacesAPIv1
{
    /**
     * List all known namespaces
     */
    @path("list") @method(HTTPMethod.GET) RenderNamespaceItem[] list() @safe;

    /**
     * List all projects within a namespace
     */
    @path(":namespace/projects") @method(HTTPMethod.GET) Project[] projects(string _namespace) @safe;
}

/**
 * Provide namespace management
 */
public final class NamespacesAPI : NamespacesAPIv1
{
    /**
     * Integrate into the root API
     */
    @noRoute void configure(URLRouter root, Database appDB) @safe
    {
        this.appDB = appDB;
        root.registerRestInterface(this);
    }

    /**
     * Render the namespace into something nice for listing, complete with
     * resolved projects.
     *
     * Returns: slice of RenderNamespaceItem
     */
    override RenderNamespaceItem[] list() @safe
    {
        RenderNamespaceItem[] ret;
        appDB.view((in tx) @safe {
            foreach (ns; tx.list!Namespace)
            {
                RenderNamespaceItem current;
                current.ns = ns;
                current.ns.description = filterMarkdown(current.ns.description);
                foreach (proj; ns.projects)
                {
                    Project p;
                    p.load(tx, proj);
                    p.description = filterMarkdown(p.description);
                    current.projects ~= p;
                }
                ret ~= current;
            }
            return NoDatabaseError;
        });
        return ret;
    }

    /**
     * List all projects within a namespace
     */
    override Project[] projects(string _namespace) @safe
    {
        Namespace ns;
        Project[] ret;
        auto err = appDB.view((in tx) @safe {
            auto err = ns.load!"slug"(tx, _namespace);
            if (!err.isNull)
            {
                return err;
            }
            ret = ns.projects.map!((projectID) {
                Project p;
                p.load(tx, projectID);
                return p;
            }).array;
            return NoDatabaseError;
        });

        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);
        return ret;
    }

private:

    Database appDB;
}

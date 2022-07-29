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

public struct RenderNamespaceItem
{
    Namespace ns;
    Project[] projects;
}

@path("api/v1/namespaces") public interface NamespacesAPIv1
{
    @path("list") @method(HTTPMethod.GET) RenderNamespaceItem[] list() @safe;
}

/**
 * Provide namespace management
 */
public final class NamespacesAPI : NamespacesAPIv1
{
    @noRoute void configure(URLRouter root, Database appDB) @safe
    {
        this.appDB = appDB;
        root.registerRestInterface(this);
    }

    /**
     * Render the namespace into something nice for listing, complete with
     * resolved projects.
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

private:

    Database appDB;
}

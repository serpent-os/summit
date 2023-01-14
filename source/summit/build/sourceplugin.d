/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.build.sourceplugin
 *
 * Source API interface to moss-deps
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.build.sourceplugin;

import moss.deps.registry;
import moss.client.metadb;

@trusted:

/**
 * Provides an interface between our source repository definitions
 * and the moss-deps transaction APIs
 */
public final class SourcePlugin : RegistryPlugin
{
    @disable this();

    /**
     * Construct a new SourcePlugin
     */
    this(MetaDB db) @safe
    {
        this.db = db;
    }

    override RegistryItem[] queryProviders(in ProviderType type, in string matcher,
            ItemFlags flags = ItemFlags.None)
    {
        return null;
    }

    override ItemInfo info(in string pkgID) const
    {
        auto mdb = cast(MetaDB) db;
        return mdb.info(pkgID);
    }

    override NullableRegistryItem queryID(in string pkgID)
    {
        return NullableRegistryItem(RegistryItem.init);
    }

    override const(Dependency)[] dependencies(in string pkgID) const
    {
        auto mdb = cast(MetaDB) db;
        return mdb.byID(pkgID).buildDependencies;
    }

    override const(Provider)[] providers(in string pkgID) const
    {
        auto mdb = cast(MetaDB) db;
        return mdb.byID(pkgID).providers;
    }

    override const(RegistryItem)[] list(in ItemFlags flags) const
    {
        return null;
    }

    override pure @property uint64_t priority() @safe @nogc nothrow const
    {
        return 0;
    }

    override Job fetchItem(in string pkgID)
    {
        return null;
    }

    override void close()
    {
    }

private:

    MetaDB db;
}

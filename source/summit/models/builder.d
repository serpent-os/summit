/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.models.builder
 *
 * Builder encapsulation
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.models.builder;

public import std.stdint : uint8_t, uint64_t;

import moss.db.keyvalue.orm;

/**
 * Identity for each Builder
 */
public alias BuilderIdentity = uint64_t;

/**
 * Simple state tracking of our builders (handshake process)
 */
public enum BuilderStatus
{
    /**
     * Any newly added Builder is unconfigured, awaiting handshake
     */
    Unconfigured = 0,

    /**
     * We've sent a handshake, awaiting response
     */
    HandshakeSent,

    /**
     * Full handshake now complete.
     */
    HandshakeComplete,

    /**
     * Active builders can be used
     */
    Active,

    /**
     * Not a fan, sorry.
     */
    Disallowed,
}

/**
 * An interface for a remote Builder
 */
public @Model struct Builder
{
    /**
     * Every builder gets a unique identity
     */
    @PrimaryKey BuilderIdentity id;

    /**
     * Full address minus port
     */
    @Indexed string uri;

    /**
     * Port number
     */
    uint16_t port;

    /**
     * The visible display name
     */
    string displayName;

    /**
     * List of contacts for the builder
     */
    string[] adminContact;

    /**
     * We track the status when looking for active builders.
     */
    BuilderStatus status;
}

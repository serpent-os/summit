/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.tokens;
 *
 * JWT support via vibe/libsodium
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module summit.tokens;

import libsodium;
import std.datetime.systime;
import std.stdint : uint64_t;
import vibe.d;
import vibe.data.json;
import std.sumtype;

/**
 * Any potential errors when dealing with tokens
 */
public enum TokenErrorCode
{
    None = 0,
    InvalidFormat,
    SigningFailed,
    VerifyFailed,
}

/**
 * Lightweight error type
 */
public struct TokenError
{
    TokenErrorCode code;
    string message;
}

public alias TokenResult = SumType!(Token, TokenError);

/**
 * We *only* use ED25519 right now.
 */
private static immutable(string) algorithm = "EdDSA";

/**
 * And we only support JWT not the rest of the JOSE spec
 */
private static immutable(string) tokenType = "JWT";

/**
 * The token header is encoded as containing
 * the following fields:
 *
 * alg:
 * typ:
 */
public struct TokenHeader
{
    /**
     * Algorithm. Always EdDSA for us
     */
    string alg = algorithm;

    /**
     * Type of token. For us, always JWT.
     */
    string typ = tokenType;

    /**
     * Encode as JSON
     */
    auto encode() @safe
    {
        return this.serializeToJsonString();
    }
}

/**
 * Our use of the payload only supports the absolute
 * base claims, i.e 7 registered.
 * We also hardcode them. :P
 */
public struct TokenPayload
{
    /**
     * When does the token expire? (UTC)
     */
    uint64_t exp;

    /**
     * When was it issued? (UTC)
     */
    uint64_t iat;

    /**
     * Subject - i.e. account name
     */
    string sub;

    /**
     * Encode as a proper string
     *
     * Returns: JSON string representation
     */
    auto encoded() @safe
    {
        return this.serializeToJsonString();
    }
}

/** 
 * A token is built from a header, payload and signature
 */
public struct Token
{
    /**
     * Fixed header for the token
     */
    TokenHeader header;

    /**
     * Payload of claims
     */
    TokenPayload payload;

    /**
     * Signature as found.
     */
    TokenSignature signature;

    /**
     * Attempts to create a Token from the given input
     * string
     */
    static TokenResult decode(in string input) @safe
    {
        Token ret;
        auto splits = input.split(".");
        if (splits.length != 3)
        {
            return TokenResult(TokenError(TokenErrorCode.InvalidFormat,
                    "Expected proper splitting in token"));
        }

        /* Load the JWT fields */
        try
        {
            ret.header = () @trusted {
                return deserializeJson!TokenHeader(cast(string) Base64URLNoPadding.decode(
                        splits[0]));
            }();
            ret.payload = () @trusted {
                return deserializeJson!TokenPayload(
                        cast(string) Base64URLNoPadding.decode(splits[1]));
            }();
        }
        catch (Exception ex)
        {
            return TokenResult(TokenError(TokenErrorCode.InvalidFormat, ex.message.idup));
        }

        if (ret.header.typ != tokenType)
        {
            return TokenResult(TokenError(TokenErrorCode.InvalidFormat,
                    "Only JWT tokens are supported"));
        }
        if (ret.header.alg != algorithm)
        {
            return TokenResult(TokenError(TokenErrorCode.InvalidFormat,
                    "Only EdDSA tokens supported"));
        }

        try
        {
            ret.signature = Base64URLNoPadding.decode(splits[2]);
        }
        catch (Exception ex)
        {
            return TokenResult(TokenError(TokenErrorCode.InvalidFormat, "Cannot read signature"));
        }
        /* Stash for verify */
        ret.signedObject = () @trusted {
            return cast(ubyte[])(input[0 .. splits[0].length + splits[1].length + 1]);
        }();
        return TokenResult(ret);
    }

    /**
     * Verify this token against the loaded signature
     *
     * Params:
     *      publicKey = Key that created the signature
     * Returns: true if the signature is valid + verified
     */
    bool verify(in TokenPublicKey publicKey) @safe
    {
        auto rc = () @trusted {
            return crypto_sign_verify_detached(signature.ptr, signedObject.ptr,
                    signedObject.length, publicKey.ptr);
        }();
        return rc == 0;
    }

private:

    ubyte[] signedObject;
}

/**
 * TokenSeed is required for generating a TokenSigningPair
 */
public alias TokenSeed = ubyte[crypto_sign_SEEDBYTES];

/**
 * TokenSignature is the raw detached signature
 */
public alias TokenSignature = ubyte[crypto_sign_BYTES];

/**
 * Construct a new random TokenSeed
 *
 * Returns: Newly RNG-initialised TokenSeed
 */
public static TokenSeed createSeed() @safe
{
    TokenSeed ret;
    () @trusted { randombytes_buf(cast(void*) ret.ptr, ret.length); }();
    return ret;
}

/**
 * A public signing key
 */
public alias TokenPublicKey = ubyte[crypto_sign_PUBLICKEYBYTES];

/**
 * A secret signing key
 */
public alias TokenSecretKey = ubyte[crypto_sign_SECRETKEYBYTES];

/**
 * The signing pair is used for libsodium..
 */
public struct TokenSigningPair
{
    /**
     * Public key for verification
     */
    TokenPublicKey publicKey;

    /**
     * Secret key for signing
     */
    TokenSecretKey secretKey;

    /**
     * Create a new signing pair with the given seed
     *
     * Params:
     *      seed = Seed to initialise the signing pair
     * Returns: A newly initialised signing pair
     */
    static TokenSigningPair create(TokenSeed seed) @safe
    {
        TokenSigningPair pair;
        auto rc = () @trusted {
            return crypto_sign_seed_keypair(pair.publicKey.ptr, pair.secretKey.ptr, seed.ptr);
        }();
        enforceHTTP(rc == 0, HTTPStatus.internalServerError,
                "Failed to construct a new TokenSigningPair");
        return pair;
    }
}

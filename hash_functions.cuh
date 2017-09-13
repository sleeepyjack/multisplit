#pragma once

#include <cstdint>

///////////////////////////////////////////////////////////////////////////////
// uint32_t hashes
///////////////////////////////////////////////////////////////////////////////

struct nvidia_hash_uint32_t {

    HOSTDEVICEQUALIFIER INLINEQUALIFIER
    uint32_t operator() (
        uint32_t x) const {

        x = (x + 0x7ed55d16) + (x << 12);
        x = (x ^ 0xc761c23c) ^ (x >> 19);
        x = (x + 0x165667b1) + (x <<  5);
        x = (x + 0xd3a2646c) ^ (x <<  9);
        x = (x + 0xfd7046c5) + (x <<  3);
        x = (x ^ 0xb55a4f09) ^ (x >> 16);

        return x;
    }
};

struct mueller_hash_uint32_t {

    HOSTDEVICEQUALIFIER INLINEQUALIFIER
    uint32_t operator() (
        uint32_t x) const {

        x = ((x >> 16) ^ x) * 0x45d9f3b;
        x = ((x >> 16) ^ x) * 0x45d9f3b;
        x = ((x >> 16) ^ x);

        return x;
    }
};


struct murmur_integer_finalizer_hash_uint32_t {

    HOSTDEVICEQUALIFIER INLINEQUALIFIER
    uint32_t operator() (
        uint32_t x) const {

        x ^= x >> 16;
        x *= 0x85ebca6b;
        x ^= x >> 13;
        x *= 0xc2b2ae35;
        x ^= x >> 16;

        return x;
    }
};


struct identity_map_t {

    template <
        typename index_t> HOSTDEVICEQUALIFIER INLINEQUALIFIER
    index_t operator() (
        index_t x) const {

        return x;
    }
};

///////////////////////////////////////////////////////////////////////////////
// uint64_t hashes
///////////////////////////////////////////////////////////////////////////////

struct murmur_hash_3_uint64_t {

    HOSTDEVICEQUALIFIER INLINEQUALIFIER
    uint64_t operator() (
        uint64_t x) const {

        x ^= x >> 33;
        x *= 0xff51afd7ed558ccd;
        x ^= x >> 33;
        x *= 0xc4ceb9fe1a85ec53;
        x ^= x >> 33;

        return x;
    }
};

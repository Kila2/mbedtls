// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MbedTLS",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .watchOS(.v6), .tvOS(.v13)
    ],
    products: [
        .library(name: "MbedTLS", type: .static, targets: ["MbedTLS"]),
        .library(name: "CMbedTLS", type: .static, targets: ["CMbedTLS"]),
    ],
    targets: [
        // 1. Public Swift module (Umbrella Target)
        .target(
            name: "MbedTLS",
            dependencies: ["CMbedTLS"],
            path: "Sources/MbedTLS"
        ),

        // 2. Underlying C module (Flattened Target)
        // This target aggregates all C source files and build settings.
        .target(
            name: "CMbedTLS",
            dependencies: [],
            path: ".", // Use root directory as the base path
            exclude: [
                // Add any necessary excludes here if they exist in your source tree
            ],
            sources: [
                // == mbedcrypto sources ==
                "library/aes.c",
                "library/aesni.c",
                "library/aesce.c",
                "library/aria.c",
                "library/asn1parse.c",
                "library/asn1write.c",
                "library/base64.c",
                "library/bignum.c",
                "library/bignum_core.c",
                "library/bignum_mod.c",
                "library/bignum_mod_raw.c",
                "library/block_cipher.c",
                "library/camellia.c",
                "library/ccm.c",
                "library/chacha20.c",
                "library/chachapoly.c",
                "library/cipher.c",
                "library/cipher_wrap.c",
                "library/constant_time.c",
                "library/cmac.c",
                "library/ctr_drbg.c",
                "library/des.c",
                "library/dhm.c",
                "library/ecdh.c",
                "library/ecdsa.c",
                "library/ecjpake.c",
                "library/ecp.c",
                "library/ecp_curves.c",
                "library/ecp_curves_new.c",
                "library/entropy.c",
                "library/entropy_poll.c",
                "library/error.c",
                "library/gcm.c",
                "library/hkdf.c",
                "library/hmac_drbg.c",
                "library/lmots.c",
                "library/lms.c",
                "library/md.c",
                "library/md5.c",
                "library/memory_buffer_alloc.c",
                "library/nist_kw.c",
                "library/oid.c",
                "library/padlock.c",
                "library/pem.c",
                "library/pk.c",
                "library/pk_ecc.c",
                "library/pk_wrap.c",
                "library/pkcs12.c",
                "library/pkcs5.c",
                "library/pkparse.c",
                "library/pkwrite.c",
                "library/platform.c",
                "library/platform_util.c",
                "library/poly1305.c",
                "library/psa_crypto.c",
                "library/psa_crypto_aead.c",
                "library/psa_crypto_cipher.c",
                "library/psa_crypto_client.c",
                "library/psa_crypto_driver_wrappers_no_static.c",
                "library/psa_crypto_ecp.c",
                "library/psa_crypto_ffdh.c",
                "library/psa_crypto_hash.c",
                "library/psa_crypto_mac.c",
                "library/psa_crypto_pake.c",
                "library/psa_crypto_rsa.c",
                "library/psa_crypto_se.c",
                "library/psa_crypto_slot_management.c",
                "library/psa_crypto_storage.c",
                "library/psa_its_file.c",
                "library/psa_util.c",
                "library/ripemd160.c",
                "library/rsa.c",
                "library/rsa_alt_helpers.c",
                "library/sha1.c",
                "library/sha256.c",
                "library/sha512.c",
                "library/sha3.c",
                "library/threading.c",
                "library/timing.c",
                "library/version.c",
                "library/version_features.c",
                
                // == mbedx509 sources ==
                "library/pkcs7.c",
                "library/x509.c",
                "library/x509_create.c",
                "library/x509_crl.c",
                "library/x509_crt.c",
                "library/x509_csr.c",
                "library/x509write.c",
                "library/x509write_crt.c",
                "library/x509write_csr.c",
                
                // == mbedtls sources ==
                "library/debug.c",
                "library/mps_reader.c",
                "library/mps_trace.c",
                "library/net_sockets.c",
                "library/ssl_cache.c",
                "library/ssl_ciphersuites.c",
                "library/ssl_client.c",
                "library/ssl_cookie.c",
                "library/ssl_debug_helpers_generated.c",
                "library/ssl_msg.c",
                "library/ssl_ticket.c",
                "library/ssl_tls.c",
                "library/ssl_tls12_client.c",
                "library/ssl_tls12_server.c",
                "library/ssl_tls13_keys.c",
                "library/ssl_tls13_server.c",
                "library/ssl_tls13_client.c",
                "library/ssl_tls13_generic.c",
                
                // == everest sources ==
                "3rdparty/everest/library/everest.c",
                "3rdparty/everest/library/x25519.c",
                "3rdparty/everest/library/Hacl_Curve25519_joined.c",
                
                // == p256m sources ==
                "3rdparty/p256-m/p256-m_driver_entrypoints.c",
                "3rdparty/p256-m/p256-m/p256-m.c"
            ],
            // Public headers are located in the "include" directory.
            // SPM will automatically create a module map.
            publicHeadersPath: "Sources/CMbedTLS/include",
            cSettings: [
                // Add all necessary header search paths
                // This allows `#include "mbedtls/ssl.h"` to work from C files
                // and `#include "common.h"` (a private header)
                .headerSearchPath("."), // For config.h at the root
                .headerSearchPath("include"),
                .headerSearchPath("library"), // For private library headers
                .headerSearchPath("3rdparty/everest/include"),
                .headerSearchPath("3rdparty/everest/include/everest"),
                .headerSearchPath("3rdparty/everest/include/everest/kremlib"),
                .headerSearchPath("3rdparty/p256-m"),
                .headerSearchPath("3rdparty/p256-m/p256-m"),
                
                // You might need to add paths for generated files if they exist
                // For example: .headerSearchPath("build/library"),
                
                // Define the config file location, as MbedTLS requires it.
                // Make sure `mbedtls_config.h` and `crypto_config.h` are accessible
                // from the header search paths.
                .define("MBEDTLS_CONFIG_FILE", to: "\"mbedtls_config.h\""),
                .define("MBEDTLS_PSA_CRYPTO_CONFIG_FILE", to: "\"psa/crypto_config.h\"")
            ]
        )
    ],
    cLanguageStandard: .c99
)

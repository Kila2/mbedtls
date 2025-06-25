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
        // 1. 公开的 Swift 模块 (Umbrella Target)
        // 用户通过 `import MbedTLS` 使用，它依赖于底层的 C 模块。
        .target(
            name: "MbedTLS",
            dependencies: ["CMbedTLS"],
            path: "Sources/MbedTLS",
        ),
        // 2. 底层的 C 模块 (Flattened Target)
        // 这是所有 C 代码的集合地。我们将所有源文件和头文件路径都放在这里。
        .target(
            name: "CMbedTLS",
            dependencies: [],
            path: ".", // 将根目录作为基础路径
            exclude: [
                "tf-psa-crypto/drivers/everest/library/legacy",
                "tf-psa-crypto/drivers/everest/library/kremlib/FStar_UInt128_extracted.c"
            ],
            sources: [
                // === Library sources ===
                "library/debug.c", "generate/library/error.c", "library/mps_reader.c",
                "library/mps_trace.c", "library/net_sockets.c", "library/pkcs7.c",
                "library/ssl_cache.c", "library/ssl_ciphersuites.c", "library/ssl_client.c",
                "library/ssl_cookie.c", "generate/library/ssl_debug_helpers_generated.c",
                "library/ssl_msg.c", "library/ssl_ticket.c", "library/ssl_tls.c",
                "library/ssl_tls12_client.c", "library/ssl_tls12_server.c",
                "library/ssl_tls13_client.c", "library/ssl_tls13_generic.c",
                "library/ssl_tls13_keys.c", "library/ssl_tls13_server.c",
                "library/timing.c", "library/version.c", "generate/library/version_features.c",
                "library/x509.c", "library/x509_create.c", "library/x509_crl.c",
                "library/x509_crt.c", "library/x509_csr.c", "library/x509_oid.c",
                "library/x509write.c", "library/x509write_crt.c", "library/x509write_csr.c",

                // === TF-PSA-Crypto Core sources ===
                "tf-psa-crypto/core/psa_crypto.c",
                "tf-psa-crypto/core/psa_crypto_client.c",
                "generate/tf-psa-crypto/core/psa_crypto_driver_wrappers_no_static.c",
                "tf-psa-crypto/core/psa_crypto_slot_management.c",
                "tf-psa-crypto/core/psa_crypto_storage.c",
                "tf-psa-crypto/core/psa_its_file.c",
                
                // === TF-PSA-Crypto Builtin Driver sources ===
                // SPM 可以直接接受目录作为源
                "tf-psa-crypto/drivers/builtin/src",

                // === TF-PSA-Crypto Everest Driver sources ===
                "tf-psa-crypto/drivers/everest/library",

                // === TF-PSA-Crypto P256-m Driver sources ===
                "tf-psa-crypto/drivers/p256-m/p256-m_driver_entrypoints.c",
                "tf-psa-crypto/drivers/p256-m/p256-m/p256-m.c"
            ],
            // 暴露给 MbedTLS 目标的公共头文件目录
            publicHeadersPath: "Sources/CMbedTLS/include",
            cSettings: [
                // 添加所有必需的头文件搜索路径
                .headerSearchPath("include"),
                .headerSearchPath("library"),
                .headerSearchPath("tf-psa-crypto/include"),
                .headerSearchPath("tf-psa-crypto/core"),
                .headerSearchPath("generate/tf-psa-crypto/core"),
                .headerSearchPath("tf-psa-crypto/drivers/builtin/include"),
                .headerSearchPath("tf-psa-crypto/drivers/builtin/src"),
                .headerSearchPath("tf-psa-crypto/drivers/everest/include"),
                .headerSearchPath("tf-psa-crypto/drivers/p256-m"),
                .headerSearchPath("tf-psa-crypto/drivers/everest/include/tf-psa-crypto/private/everest"),
                .headerSearchPath("tf-psa-crypto/drivers/everest/include/tf-psa-crypto/private/everest/kremlib"),
                
                // 添加必要的宏定义
                .define("MBEDTLS_CONFIG_FILE", to: "\"mbedtls_config.h\""),
                .define("MBEDTLS_PSA_CRYPTO_CONFIG_FILE", to: "\"psa/crypto_config.h\"")
            ]
        ),
    ],
    cLanguageStandard: .c99
)

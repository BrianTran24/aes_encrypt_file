// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "aes_encrypt_file",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "aes-encrypt-file", targets: ["aes_encrypt_file"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        // Swift Package Manager cannot mix C and Swift in one target, so the
        // C crypto engine is a target of its own that the plugin depends on.
        .target(
            name: "aes_encrypt_file_c",
            linkerSettings: [
                .linkedFramework("Security")
            ]
        ),
        .target(
            name: "aes_encrypt_file",
            dependencies: [
                "aes_encrypt_file_c",
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ]
        ),
    ]
)

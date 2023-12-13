// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainSecurity",
    platforms: [
            .iOS(.v14),
        ],
    products: [
        .library(
            name: "KeychainSecurity",
            targets: ["KeychainSecurity"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", .exact("1.5.2"))
    ],
    targets: [
        .target(
            name: "KeychainSecurity",
            dependencies: [.product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "KeychainSecurityTests",
            dependencies: ["KeychainSecurity"]),
    ]
)

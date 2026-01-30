// swift-tools-version: 6.0
// CartoMix - 100% macOS Native DJ Set Prep Copilot (Codename: Dardania)

import PackageDescription

let package = Package(
    name: "Dardania",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Main macOS application
        .executable(
            name: "Dardania",
            targets: ["Dardania"]),
        // Core library (database, similarity, export)
        .library(
            name: "DardaniaCore",
            targets: ["DardaniaCore"]),
        // XPC Analyzer service
        .executable(
            name: "AnalyzerXPC",
            targets: ["AnalyzerXPC"]),
    ],
    dependencies: [
        // Database
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
        // Logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
    ],
    targets: [
        // Main App
        .executableTarget(
            name: "Dardania",
            dependencies: [
                "DardaniaCore",
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/Dardania"),

        // Core library
        .target(
            name: "DardaniaCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/DardaniaCore"),

        // XPC Service
        .executableTarget(
            name: "AnalyzerXPC",
            dependencies: [
                "DardaniaCore",
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/AnalyzerXPC"),

        // Core Tests
        .testTarget(
            name: "DardaniaCoreTests",
            dependencies: [
                "DardaniaCore",
            ],
            path: "Tests/DardaniaCoreTests"),

        // XPC Tests
        .testTarget(
            name: "AnalyzerXPCTests",
            dependencies: [
                "DardaniaCore",
            ],
            path: "Tests/AnalyzerXPCTests"),

        // Golden Export Tests
        .testTarget(
            name: "GoldenTests",
            dependencies: [
                "DardaniaCore",
            ],
            path: "Tests/GoldenTests"),
    ]
)

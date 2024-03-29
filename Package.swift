// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "CRepository",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "CRepository",
            targets: [
                "CRepository"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", from: "0.53.0"),
        .package(url: "https://github.com/realm/realm-cocoa", from: "10.48.1"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .macro(
            name: "CRepositoryMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
        .target(
            name: "CRepository",
            dependencies: [
                "CRepositoryMacros",
                .product(name: "RealmSwift", package: "realm-cocoa")
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
        .executableTarget(
            name: "CRepositoryClient",
            dependencies: [
                "CRepository"
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
        .testTarget(
            name: "CRepositoryTests",
            dependencies: [
                "CRepository"
            ],
            path: "CRepositoryTests",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)

let defaultSettings: [SwiftSetting] = [.enableExperimentalFeature("StrictConcurrency=minimal")]
package.targets.forEach { target in
    if var settings = target.swiftSettings, !settings.isEmpty {
        settings.append(contentsOf: defaultSettings)
        target.swiftSettings = settings
    } else {
        target.swiftSettings = defaultSettings
    }
}


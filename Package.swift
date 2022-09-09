// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CRepository",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CRepository",
            targets: ["CRepository"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa.git", .exact ("10.28.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CRepository",
            dependencies: [
                .product(name: "RealmSwift", package: "Realm")
            ],
            path: "Sources",
            exclude: ["Info.plist"]),
        .testTarget(
            name: "CRepositoryTests",
            dependencies: ["CRepository"],
            path: "Tests",
            exclude: ["Info.plist"]),
    ]
)

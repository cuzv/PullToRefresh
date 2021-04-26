// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PullToRefresh",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "PullToRefresh", targets: ["PullToRefresh"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "PullToRefresh",
            dependencies: [],
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [.v5]
)

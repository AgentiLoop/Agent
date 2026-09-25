// swift-tools-version: 6.4
// TypeSafeKit — Swift client for the TypeSafe AI System One API (Jev).
// Wire protocol: POST https://api.typesafe.ai/v1/systemone, GET /v1/models.

import PackageDescription

let package = Package(
    name: "TypeSafeKit",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(name: "TypeSafeKit", targets: ["TypeSafeKit"]),
        .library(name: "TypeSafeMiddleware", targets: ["TypeSafeMiddleware"]),
    ],
    targets: [
        .target(name: "TypeSafeKit"),
        .target(name: "TypeSafeMiddleware", dependencies: ["TypeSafeKit"]),
        .testTarget(name: "TypeSafeKitTests", dependencies: ["TypeSafeKit", "TypeSafeMiddleware"]),
    ]
)

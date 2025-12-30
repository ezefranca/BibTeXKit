// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BibTeXKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "BibTeXKit",
            targets: ["BibTeXKit"]
        ),
    ],
    targets: [
        .target(
            name: "BibTeXKit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "BibTeXKitTests",
            dependencies: ["BibTeXKit"]
        ),
    ]
)

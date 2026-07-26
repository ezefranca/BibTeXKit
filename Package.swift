// swift-tools-version: 6.3

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
        .library(
            name: "BibTeXKitDynamic",
            type: .dynamic,
            targets: ["BibTeXKit"]
        ),
    ],
    targets: [
        .target(name: "BibTeXKit"),
        .testTarget(
            name: "BibTeXKitTests",
            dependencies: ["BibTeXKit"]
        ),
        .testTarget(
            name: "BibTeXKitPerformanceTests",
            dependencies: ["BibTeXKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

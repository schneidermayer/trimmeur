// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "trimmeur",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "TrimmeurCore", targets: ["TrimmeurCore"]),
        .executable(name: "trimmeur", targets: ["TrimmeurMacOS"]),
    ],
    targets: [
        .target(name: "TrimmeurCore"),
        .executableTarget(
            name: "TrimmeurMacOS",
            dependencies: ["TrimmeurCore"],
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "TrimmeurCoreTests",
            dependencies: ["TrimmeurCore"]
        ),
    ]
)

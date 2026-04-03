// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TransferEngine",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TransferEngine", targets: ["TransferEngine"]),
    ],
    dependencies: [
        .package(path: "../RcloneKit"),
    ],
    targets: [
        .target(
            name: "TransferEngine",
            dependencies: ["RcloneKit"],
            path: "Sources/TransferEngine"
        ),
        .testTarget(
            name: "TransferEngineTests",
            dependencies: ["TransferEngine", "RcloneKit"],
            path: "Tests/TransferEngineTests"
        ),
    ]
)

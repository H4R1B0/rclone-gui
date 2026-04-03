// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FileBrowser",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FileBrowser", targets: ["FileBrowser"]),
    ],
    dependencies: [
        .package(path: "../RcloneKit"),
    ],
    targets: [
        .target(
            name: "FileBrowser",
            dependencies: ["RcloneKit"],
            path: "Sources/FileBrowser"
        ),
        .testTarget(
            name: "FileBrowserTests",
            dependencies: ["FileBrowser", "RcloneKit"],
            path: "Tests/FileBrowserTests"
        ),
    ]
)

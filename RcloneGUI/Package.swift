// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RcloneGUI",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "RcloneGUI", targets: ["RcloneGUI"]),
    ],
    targets: [
        .executableTarget(
            name: "RcloneGUI",
            path: "RcloneGUI"
        ),
    ]
)

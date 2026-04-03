// swift-tools-version: 5.10
import PackageDescription
import Foundation

// Compute absolute path to Resources/lib from Package.swift location
let packageDir = URL(fileURLWithPath: #file).deletingLastPathComponent().path
let libPath = "\(packageDir)/../../Resources/lib"

let package = Package(
    name: "RcloneKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RcloneKit", targets: ["RcloneKit"]),
    ],
    targets: [
        .systemLibrary(
            name: "CRclone",
            path: "Sources/CRclone"
        ),
        .target(
            name: "RcloneKit",
            dependencies: ["CRclone"],
            path: "Sources/RcloneKit",
            linkerSettings: [
                .unsafeFlags(["-L\(libPath)"]),
            ]
        ),
        .testTarget(
            name: "RcloneKitTests",
            dependencies: ["RcloneKit"],
            path: "Tests/RcloneKitTests"
        ),
    ]
)

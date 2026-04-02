// swift-tools-version: 5.10
import PackageDescription

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
                .unsafeFlags(["-L../../Resources/lib", "-Wl,-rpath,@executable_path/../Frameworks"]),
            ]
        ),
        .testTarget(
            name: "RcloneKitTests",
            dependencies: ["RcloneKit"],
            path: "Tests/RcloneKitTests"
        ),
    ]
)

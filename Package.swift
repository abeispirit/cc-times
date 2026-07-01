// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "mtimes",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "mtimes",
            path: "Sources"
        )
    ]
)

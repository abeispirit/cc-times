// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "cc-times",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "cc-times",
            path: "Sources"
        )
    ]
)

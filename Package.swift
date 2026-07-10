// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KuaiClip",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KuaiClip", targets: ["KuaiClip"])
    ],
    targets: [
        .executableTarget(
            name: "KuaiClip",
            path: "Sources/KuaiClip",
            resources: [
                .process("Resources")
            ]
        )
    ]
)

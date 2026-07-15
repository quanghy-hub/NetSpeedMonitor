// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetSpeedMonitor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "NetSpeedMonitor",
            targets: ["NetSpeedMonitor"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NetSpeedMonitor",
            dependencies: [],
            path: "NetSpeedMonitor",
            resources: [
                .process("Assets.xcassets"),
                .process("icon.png")
            ]
        ),
    ]
)

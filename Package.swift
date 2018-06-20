// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "WLoveServer",
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.5"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0-rc.4.0.1"),
        .package(url: "https://github.com/vapor/redis.git", from: "3.0.0-rc.3"),
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0-rc.2")

    ],
    targets: [
        .target(name: "App", dependencies: ["FluentMySQL", "Vapor","Redis","Leaf"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)


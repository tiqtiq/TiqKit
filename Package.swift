// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "TiqKit",
    products: [
        .library(
            name: "TiqKit",
            targets: ["TiqKit"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TiqKit",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-enable-experimental-concurrency"
                ])
            ]),
        .testTarget(
            name: "TiqKitTests",
            dependencies: ["TiqKit"],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-enable-experimental-concurrency"
                ])
            ])
    ]
)

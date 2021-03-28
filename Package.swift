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
            dependencies: []),
        .testTarget(
            name: "TiqKitTests",
            dependencies: ["TiqKit"]),
    ]
)

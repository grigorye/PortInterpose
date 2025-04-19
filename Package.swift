// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "PortInterpose",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PortInterpose",
            type: .dynamic,
            targets: ["PortInterposeHook"],
        ),
    ],
    targets: [
        .target(
            name: "PortLogic",
        ),
        .target(
            name: "PortInterposeHook",
            dependencies: ["PortLogic"],
            publicHeadersPath: ".",
        ),
        .testTarget(
            name: "PortLogicTests",
            dependencies: ["PortLogic"],
        ),
        .testTarget(
            name: "PortInterposeTests",
            dependencies: ["PortInterposeHook"],
            resources: [
                .copy("Scripts")
            ]
        )
    ]
)

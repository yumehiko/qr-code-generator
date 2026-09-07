// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "QRCodeGenerator",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "QRCodeGenerator",
            targets: ["QRCodeGenerator"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "QRCodeGenerator",
            dependencies: [],
            path: "Sources",
            exclude: [
                "Resources/generate_icons.py",
                "Resources/icon.svg"
            ],
            resources: [
                .copy("Resources/Assets.xcassets")
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-cross-module-optimization"
                ], .when(configuration: .release)),
                .unsafeFlags([
                    "-Xfrontend", "-warn-long-function-bodies=100",
                    "-Xfrontend", "-warn-long-expression-type-checking=100"
                ], .when(configuration: .debug))
            ],
            linkerSettings: [
                .linkedFramework("CoreImage"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "QRCodeGeneratorTests",
            dependencies: ["QRCodeGenerator"],
            path: "Tests"
        )
    ]
)

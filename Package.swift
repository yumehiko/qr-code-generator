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
            path: "Sources"
        )
    ]
)
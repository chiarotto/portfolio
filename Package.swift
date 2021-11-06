// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "portfolio",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git", from: "1.0.1"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.14.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.1.0")

    ],
    targets: [
        .target(
            name: "portfolio",
            dependencies: [
                "Stencil",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),

        .testTarget(
            name: "portfolioTests",
            dependencies: ["portfolio"]),
    ]
)

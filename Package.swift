// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLIBPNG",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftLIBPNG",
            targets: ["SwiftLIBPNG"]),
    ],
    dependencies: [],
    targets: [
        .systemLibrary(name: "png", pkgConfig: "libpng", providers: [.apt(["libpng-dev"]), .brew(["libpng"])]),
        .target(
            name: "SwiftLIBPNG",
            dependencies: ["png"]),
        .testTarget(
            name: "SwiftLIBPNGTests",
            dependencies: ["SwiftLIBPNG"]),
    ]
)

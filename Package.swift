// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Directory",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Directory",
            targets: ["Directory"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nashysolutions/Cache.git", .upToNextMinor(from: "2.0.0")),
        .package(url: "https://github.com/JohnSundell/Files", .upToNextMinor(from: "4.2.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Directory",
            dependencies: ["Files", "Cache"]
        ),
        .testTarget(
            name: "DirectoryTests",
            dependencies: ["Directory", "Files"],
            resources: [.process("Resources")]
        )
    ]
)

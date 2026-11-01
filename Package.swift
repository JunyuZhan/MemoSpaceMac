// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MemoSpaceMac",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MemoSpaceKit", targets: ["MemoSpaceKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/amosavian/AMSMB2.git", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        .target(
            name: "MemoSpaceKit",
            dependencies: [.product(name: "AMSMB2", package: "AMSMB2")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MemoSpaceKitTests",
            dependencies: ["MemoSpaceKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)

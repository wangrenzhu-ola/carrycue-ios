// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CarryCue",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [.library(name: "CarryCueCore", targets: ["CarryCueCore"])],
    targets: [
        .target(name: "CarryCueCore", path: "CarryCueCore"),
        .testTarget(name: "CarryCueCoreTests", dependencies: ["CarryCueCore"], path: "CarryCueCoreTests")
    ],
    swiftLanguageVersions: [.v5]
)

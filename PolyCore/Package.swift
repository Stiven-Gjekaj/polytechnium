// swift-tools-version: 6.0
import PackageDescription

// The parts of the app that do not need a screen. They build and test on a Mac
// with `swift test`, so a test does not need a simulator.
let package = Package(
    name: "PolyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "PolyCore", targets: ["PolyCore"])],
    targets: [
        .target(name: "PolyCore"),
        .testTarget(name: "PolyCoreTests", dependencies: ["PolyCore"]),
    ]
)

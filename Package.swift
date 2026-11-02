// swift-tools-version: 6.0
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import PackageDescription

let package = Package(
    name: "Bogenzeit",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "Bogenzeit", targets: ["Bogenzeit"]),
        .library(name: "BogenzeitUI", targets: ["BogenzeitUI"]),
    ],
    targets: [
        .target(name: "Bogenzeit"),
        .target(name: "BogenzeitUI", dependencies: ["Bogenzeit"]),
        .testTarget(name: "BogenzeitTests", dependencies: ["Bogenzeit"]),
    ],
    swiftLanguageModes: [.v6]
)

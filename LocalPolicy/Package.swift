// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LocalPolicy",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HayabusaLocalPolicy", targets: ["HayabusaLocalPolicy"]),
    ],
    targets: [
        .target(name: "HayabusaLocalPolicy"),
        .testTarget(
            name: "HayabusaLocalPolicyTests",
            dependencies: ["HayabusaLocalPolicy"]
        ),
    ]
)

// swift-tools-version: 5.10
import PackageDescription

// Absolute path to llama.cpp build artifacts
let llamaBuildDir = "\(Context.packageDirectory)/vendor/llama.cpp/build"

let package = Package(
    name: "Hayabusa",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "LocalPolicy"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        // Pin revision: upstream no longer tracks Swift 5.10; main uses swift-tools 6.1 (Xcode ≥16.3).
        // Bump intentionally after `swift package update` + local `harness full`.
        .package(url: "https://github.com/ml-explore/mlx-swift-lm.git", revision: "7e2b7107be52ffbfe488f3c7987d3f52c1858b4b"),
        .package(url: "https://github.com/huggingface/swift-huggingface.git", from: "0.8.1"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "CLlama",
            path: "Sources/CLlama",
            linkerSettings: [
                .unsafeFlags([
                    "-L\(llamaBuildDir)/src",
                    "-L\(llamaBuildDir)/ggml/src",
                    "-L\(llamaBuildDir)/ggml/src/ggml-metal",
                    "-L\(llamaBuildDir)/ggml/src/ggml-blas",
                ]),
                .linkedLibrary("llama"),
                .linkedLibrary("ggml"),
                .linkedLibrary("ggml-base"),
                .linkedLibrary("ggml-metal"),
                .linkedLibrary("ggml-cpu"),
                .linkedLibrary("ggml-blas"),
                .linkedLibrary("c++"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("MetalPerformanceShaders"),
                .linkedFramework("Foundation"),
                .linkedFramework("Accelerate"),
            ]
        ),
        .executableTarget(
            name: "Hayabusa",
            dependencies: [
                "HayabusaKit",
                // Composition root must link CLlama: SPM does not always propagate linkerSettings
                // from nested targets to the top-level executable (CI: ld: library 'llama' not found).
                "CLlama",
            ],
            path: "Sources/HayabusaCLI"
        ),
        .target(
            name: "HayabusaKit",
            dependencies: [
                .product(name: "HayabusaLocalPolicy", package: "LocalPolicy"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
                .product(name: "Tokenizers", package: "swift-transformers"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                "CLlama",
            ],
            path: "Sources/HayabusaKit",
            exclude: ["Resources/genome-viewer.html"]
        ),
        .testTarget(
            name: "HayabusaIntegrationTests",
            dependencies: [
                "HayabusaKit",
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
            path: "Tests/HayabusaIntegrationTests"
        ),
    ]
)

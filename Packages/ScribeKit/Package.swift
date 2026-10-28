// swift-tools-version: 6.0
import PackageDescription

// MLX (GPU LLM) is intentionally NOT a dependency here: it needs Xcode's Metal
// toolchain, and keeping it in the app target lets this package build and test
// with Command Line Tools alone. See App/Intelligence/MLXProvider.swift.
let package = Package(
    name: "ScribeKit",
    platforms: [.macOS("14.4")],
    products: [
        .library(
            name: "ScribeKit",
            targets: [
                "ScribeModels", "AudioCapture", "Transcription", "Diarization", "Intelligence", "Storage", "ScribeCore",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "1.1.1"),
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.17.7"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1"),
    ],
    targets: [
        .target(name: "ScribeModels"),
        .target(name: "AudioCapture", dependencies: ["ScribeModels"]),
        .target(
            name: "Transcription",
            dependencies: [
                "ScribeModels",
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "FluidAudio", package: "FluidAudio"),
            ]
        ),
        .target(
            name: "Diarization",
            dependencies: [
                "ScribeModels",
                .product(name: "FluidAudio", package: "FluidAudio"),
            ]
        ),
        .target(name: "Intelligence", dependencies: ["ScribeModels"]),
        .target(
            name: "Storage",
            dependencies: [
                "ScribeModels",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .target(
            name: "ScribeCore",
            dependencies: [
                "ScribeModels", "AudioCapture", "Transcription", "Diarization", "Intelligence", "Storage",
            ]
        ),
        .testTarget(name: "ScribeModelsTests", dependencies: ["ScribeModels"]),
        .testTarget(name: "DiarizationTests", dependencies: ["Diarization"]),
        .testTarget(name: "StorageTests", dependencies: ["Storage"]),
        .testTarget(name: "ScribeCoreTests", dependencies: ["ScribeCore"]),
    ]
)

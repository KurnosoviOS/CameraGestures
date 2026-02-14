// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ModelTraining",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        .executable(
            name: "ModelTraining",
            targets: ["ModelTraining"]
        ),
    ],
    dependencies: [
        // Dependencies for the ModelTraining app
        // Add any Swift packages here if needed
    ],
    targets: [
        .executableTarget(
            name: "ModelTraining",
            dependencies: [],
            path: "Sources/ModelTraining",
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution"])
            ],
            linkerSettings: [
                // Link against the CameraGestures C++ library
                .linkedLibrary("CameraGestures"),
                .linkedLibrary("HandsRecognizing"),
                .linkedLibrary("GestureModel"),
                // Link against system frameworks
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("CoreML"),
                .linkedFramework("Vision")
            ]
        ),
        .testTarget(
            name: "ModelTrainingTests",
            dependencies: ["ModelTraining"]
        ),
    ]
)

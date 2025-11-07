// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pdf-palette",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "pdf-palette",
            dependencies: [],
            path: "pdf-palette",
            sources: ["main.swift", "PDFManager.swift"]
        )
    ]
)

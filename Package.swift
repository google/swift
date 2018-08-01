// swift-tools-version:4.1

import PackageDescription

let package = Package(
  name: "swiftformat",
  dependencies: [
    .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
    .package(url: "https://github.com/allevato/swift-syntax", .branch("swift-4.2-generated")),
  ],
  targets: [
    .target(
      name: "swiftformat",
      dependencies: ["Rules", "Core", "Configuration", "PrettyPrint", "SwiftSyntax", "Utility"]),
    .target(
      name: "generate-pipeline",
      dependencies: ["SwiftSyntax"]),
    .target(
      name: "Rules",
      dependencies: ["Core", "Configuration"]),
    .target(
      name: "PrettyPrint",
      dependencies: ["Core", "Configuration"]),
    .target(
      name: "Core",
      dependencies: ["Configuration"]),
    .target(
      name: "Configuration",
      dependencies: []),
    .testTarget(
      name: "SwiftFormatTests",
      dependencies: ["Core", "Configuration", "Rules", "PrettyPrint", "SwiftSyntax"]),
    .testTarget(
      name: "PrettyPrinterTests",
      dependencies: ["Core", "Configuration", "Rules", "PrettyPrint", "SwiftSyntax"]),
  ]
)

// swift-tools-version:4.2
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Formatter open source project.
//
// Copyright (c) 2018 Apple Inc. and the Swift Formatter project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Formatter project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
  name: "swift-format",
  products: [
    .executable(name: "swift-format", targets: ["swift-format"]),
    .library(name: "SwiftFormat", targets: ["SwiftFormat"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
    .package(url: "https://github.com/apple/swift-syntax", .revision("xcode11-beta1")),
  ],
  targets: [
    .target(
      name: "CCommonMark",
      exclude: [
        "cmark/api_test",
        // We must exclude main.c or SwiftPM will treat this target as an executable target instead
        // of a library, and we won't be able to import it from the CommonMark Swift module.
        "cmark/src/main.c",
        "cmark/test",
      ]
    ),
    .target(name: "CommonMark", dependencies: ["CCommonMark"]),
    .target(
      name: "SwiftFormat",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftFormatWhitespaceLinter",
        "SwiftSyntax",
      ]
    ),
    .target(name: "SwiftFormatConfiguration"),
    .target(name: "SwiftFormatCore", dependencies: ["SwiftFormatConfiguration", "SwiftSyntax"]),
    .target(
      name: "SwiftFormatRules",
      dependencies: ["SwiftFormatCore", "SwiftFormatConfiguration"]
    ),
    .target(
      name: "SwiftFormatPrettyPrint",
      dependencies: ["SwiftFormatCore", "SwiftFormatConfiguration"]
    ),
    .target(
      name: "SwiftFormatWhitespaceLinter",
      dependencies: [
        "SwiftFormatCore",
        "SwiftSyntax",
      ]
    ),
    .target(name: "generate-pipeline", dependencies: ["SwiftSyntax"]),
    .target(
      name: "swift-format",
      dependencies: [
        "SwiftFormat",
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftSyntax",
        "Utility",
      ]
    ),
    .testTarget(name: "CommonMarkTests", dependencies: ["CommonMark"]),
    .testTarget(
      name: "SwiftFormatRulesTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftSyntax",
      ]
    ),
    .testTarget(
      name: "SwiftFormatPrettyPrintTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftSyntax",
      ]
    ),
    .testTarget(
      name: "SwiftFormatWhitespaceLinterTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatWhitespaceLinter",
        "SwiftSyntax",
      ]
    ),
  ]
)

// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-di",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
  ],
  products: [
    .library(
      name: "DI",
      targets: ["DI"]
    ),
    .library(
      name: "DIMacros",
      targets: ["MacroInterfaces", "MacroImplementations"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"602.0.0")
  ],
  targets: [
    .target(
      name: "DI"
    ),
    .target(
      name: "MacroInterfaces",
      dependencies: [
        "MacroImplementations"
      ]
    ),
    .macro(
      name: "MacroImplementations",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "DITests",
      dependencies: [
        "DI",
        "MacroInterfaces",
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)

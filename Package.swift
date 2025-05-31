// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "swift-di",
  products: [
    .library(
      name: "DI",
      targets: ["DI"]
    )
  ],
  targets: [
    .target(
      name: "DI"
    ),
    .testTarget(
      name: "DITests",
      dependencies: ["DI"]
    ),
  ]
)

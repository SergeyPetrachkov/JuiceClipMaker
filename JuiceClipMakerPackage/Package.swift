// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "JuiceClipMakerPackage",
  platforms: [.iOS("12.0")],
  products: [
    .library(
      name: "JuiceClipMakerPackage",
      targets: ["JuiceClipMakerPackage"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "JuiceClipMakerPackage",
      dependencies: []),
    .testTarget(
      name: "JuiceClipMakerPackageTests",
      dependencies: ["JuiceClipMakerPackage"]),
  ]
)

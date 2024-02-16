// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkdownView",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "MarkdownView",
            targets: ["MarkdownView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", branch:"main")
    ],
    targets: [
        .target(
            name: "MarkdownView",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
        .testTarget(
            name: "MarkdownViewTests",
            dependencies: ["MarkdownView"]),
    ]
)

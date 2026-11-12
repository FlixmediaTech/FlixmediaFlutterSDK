// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flix_inpage",
    platforms: [.iOS("15.6")],
    products: [
        .library(name: "flix-inpage", targets: ["flix_inpage"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/FlixmediaTech/FlixMediaSPM.git", exact: "1.0.7")
    ],
    targets: [
        .target(
            name: "flix_inpage",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "FlixMediaSDK", package: "FlixMediaSPM")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        )
    ]
)

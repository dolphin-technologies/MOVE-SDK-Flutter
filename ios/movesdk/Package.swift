// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "movesdk",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "movesdk", targets: ["movesdk"])
    ],
    dependencies: [
		.package(url: "https://github.com/dolphin-technologies/MOVE-iOS-Packages", from: "2.14.3")
	],
    targets: [
        .target(
            name: "movesdk",
            dependencies: [
				.product(name: "DolphinMoveSDK", package: "move-ios-packages")
			],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)

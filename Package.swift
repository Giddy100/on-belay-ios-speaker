// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OnBelay",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "OnBelay",
            targets: ["OnBelay"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "OnBelay",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "OnBelay"
        )
    ]
)

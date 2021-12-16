// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//@f:0
let package = Package(
    name: "StringIntern",
    platforms: [ .macOS(.v11), .tvOS(.v14), .iOS(.v14), .watchOS(.v7) ],
    products: [
        .library(name: "StringIntern", targets: [ "StringIntern" ]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "StringIntern", exclude: [ "Info.plist", ]),
        .testTarget(name: "StringInternTests", dependencies: [ "StringIntern" ], exclude: [ "Info.plist", ]),
    ])
//@f:1

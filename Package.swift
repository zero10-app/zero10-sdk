// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "ZERO10SDK",
    products: [
        .library(name: "ZERO10SDK", targets: ["ZERO10SDK"]),
    ],
    targets: [
        .binaryTarget(
            name: "ZERO10SDK",
            url: "https://cdn.010.community/storage/ZERO10SDK_1.0.1.zip",
            checksum: "d103d9d092e9efe1ac61da279ae0078742b1fc69790d622d3e36ff4edfcd6276"
        ),
    ]
)

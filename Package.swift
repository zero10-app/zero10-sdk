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
            checksum: "d1052b12de92ce5536b84979b9b985e39ccd748a304c181dc95da82f8bfdb713"
        ),
    ]
)

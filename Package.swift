// swift-tools-version: 5.9
// This Package.swift is for reference only.
// The actual Xcode project manages dependencies via SPM integration.
// When creating the Xcode project on Mac, add these packages:
//
// 1. supabase-swift: https://github.com/supabase/supabase-swift
//    - Branch: main (or latest stable tag)
//    - Products needed: Supabase
//
// See XCODE_SETUP.md for step-by-step instructions.

import PackageDescription

let package = Package(
    name: "BabyApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "BabyApp", targets: ["BabyApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "BabyApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "BabyApp"
        )
    ]
)

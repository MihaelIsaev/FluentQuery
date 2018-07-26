// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FluentQuery",
    products: [
        // Swift lib that gives ability to build complex raw SQL-queries in a more easy way using KeyPaths
        .library(name: "FluentQuery", targets: ["FluentQuery"]),
        ],
    dependencies: [
        // Swift ORM framework (queries, models, and relations) for building NoSQL and SQL database integrations.
        .package(url: "https://github.com/vapor/postgresql.git", from: "1.0.0"),
        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
        ],
    targets: [
        .target(name: "FluentQuery", dependencies: ["PostgreSQL", "NIO"]),
        .testTarget(name: "FluentQueryTests", dependencies: ["FluentQuery", "PostgreSQL"]),
        ]
)

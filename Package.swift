// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FluentQuery",
    products: [
        // Swift lib that gives ability to build complex raw SQL-queries in a more easy way using KeyPaths
        .library(name: "FluentQuery", targets: ["FluentQuery"]),
        .library(name: "FluentQueryPostgreSQL", targets: ["FluentQuery", "FluentQueryPostgreSQL"]),
        .library(name: "FluentQueryMySQL", targets: ["FluentQuery", "FluentQueryMySQL"]),
    ],
    dependencies: [
        // Swift ORM framework (queries, models, and relations) for building NoSQL and SQL database integrations.
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0-rc.2.1.1"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0-rc")
    ],
    targets: [
        .target(name: "FluentQuery", dependencies: ["Fluent"]),
        .target(name: "FluentQueryPostgreSQL", dependencies: ["FluentPostgreSQL", "FluentQuery"]),
        .target(name: "FluentQueryMySQL", dependencies: ["FluentMySQL", "FluentQuery"]),
        .testTarget(name: "FluentQueryTests", dependencies: ["FluentQuery", "FluentPostgreSQL", "FluentMySQL"]),
    ]
)

// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TableSurf",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "TableSurfCore", targets: ["TableSurfCore"]),
        .executable(name: "TableSurf", targets: ["TableSurfApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.25.0"),
        .package(path: "ThirdParty/mysql-nio"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.25.0"),
    ],
    targets: [
        .target(
            name: "TableSurfCore",
            dependencies: [
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "MySQLNIO", package: "mysql-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ]
        ),
        .executableTarget(
            name: "TableSurfApp",
            dependencies: ["TableSurfCore"]
        ),
        .testTarget(
            name: "TableSurfCoreTests",
            dependencies: ["TableSurfCore"]
        ),
    ]
)

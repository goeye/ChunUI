// swift-tools-version: 6.2
// ═══════════════════════════════════════════════════════════════════════════
// ChunUI · Monochrome-quality SwiftUI design system
// 与宿主工程同构的并发语义：Swift 5 语言模式 + 默认 MainActor 隔离 + 渐进并发
// ═══════════════════════════════════════════════════════════════════════════
import PackageDescription

let package = Package(
    name: "ChunUI",
    defaultLocalization: "en",
    platforms: [
        .iOS("18.6"),
        .macOS("13.0")
    ],
    products: [
        .library(name: "ChunUI", targets: ["ChunUI"]),
        .library(name: "ChunUIDemo", targets: ["ChunUIDemo"]),
    ],
    dependencies: [
        // 唯一第三方：按钮 glow/shake 按压质感（MIT · EmergeTools）
        .package(url: "https://github.com/EmergeTools/Pow", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ChunUI",
            dependencies: [.product(name: "Pow", package: "Pow")],
            path: "Sources/ChunUI",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        // 消费者视角的活体示例 + 公开 API 面编译测试（从包外构造旗舰组件）
        .target(
            name: "ChunUIDemo",
            dependencies: ["ChunUI"],
            path: "Sources/ChunUIDemo",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        )
    ]
)

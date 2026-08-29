/**
 * [INPUT]: 依赖 SwiftUI GlassEffectContainer / glassEffectUnion（iOS 26）、ccGlassEffect 软玻璃降级、EnvironmentValues
 * [OUTPUT]: 对外提供 CCGlassCluster（并排玻璃钮融合簇）、CCGlassUnion 环境值（簇内成员据此加入同一 glassEffectUnion）、ccGlassClusterMember 环境值（18.6–25 成员放弃自描玻璃，由簇统一一枚胶囊承托）、View.ccGlassUnion(_:) 成员侧修饰
 * [POS]: Components 的玻璃融合范式唯一出口：两枚及以上相邻 GlassIconButton/GlassIconButtonLabel 一律包进 CCGlassCluster——iOS 26 走 Apple Liquid Glass 官方融合（GlassEffectContainer + glassEffectUnion 合成一块连续玻璃并可形变），18.6–25 用一枚 capsule 软玻璃承托全部成员做同形降级；禁止业务页手排两枚独立玻璃圆钮
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 环境值：簇内成员如何参与融合
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// iOS 26：同一 union id + namespace 的玻璃成员会被系统合成一块玻璃
public struct CCGlassUnion: Equatable {
    public let id: String
    public let namespace: Namespace.ID

    public init(id: String, namespace: Namespace.ID) {
        self.id = id
        self.namespace = namespace
    }
}

private struct CCGlassUnionKey: EnvironmentKey {
    static let defaultValue: CCGlassUnion? = nil
}

private struct CCGlassClusterMemberKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// 非 nil 时成员应加入该 union（iOS 26）
    var ccGlassUnion: CCGlassUnion? {
        get { self[CCGlassUnionKey.self] }
        set { self[CCGlassUnionKey.self] = newValue }
    }

    /// true 时成员处于 18.6–25 降级簇内：不再自描玻璃，由簇统一承托
    var ccGlassClusterMember: Bool {
        get { self[CCGlassClusterMemberKey.self] }
        set { self[CCGlassClusterMemberKey.self] = newValue }
    }
}

public extension View {
    /// 成员侧：iOS 26 加入 union；旧系统原样返回
    @ViewBuilder
    func ccGlassUnion(_ union: CCGlassUnion?) -> some View {
        if #available(iOS 26, *), let union {
            self.glassEffectUnion(id: union.id, namespace: union.namespace)
        } else {
            self
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCGlassCluster（并排玻璃钮融合簇）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 并排玻璃钮的融合容器：内容按水平排列，成员之间的玻璃合成一块
///
/// iOS 26：`GlassEffectContainer(spacing:)` 共享采样 + 成员 `glassEffectUnion` 同 id → 官方融合（Apple「Grouping glass」范式）；
/// iOS 18.6–25：成员不自描玻璃，簇外套一枚 capsule 软玻璃承托，保持同一轮廓
public struct CCGlassCluster<Content: View>: View {
    private let spacing: CGFloat
    private let content: () -> Content
    @Namespace private var unionNS

    /// - Parameter spacing: 成员间距；默认 2pt——足够近到系统把两枚圆钮合成一枚胶囊
    public init(spacing: CGFloat = 2, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    @ViewBuilder
    public var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing + 16) {
                HStack(spacing: spacing) {
                    content()
                }
                .environment(\.ccGlassUnion, CCGlassUnion(id: "cc.glass.cluster", namespace: unionNS))
            }
        } else {
            HStack(spacing: spacing) {
                content()
            }
            .environment(\.ccGlassClusterMember, true)
            .softGlassStyle(.capsule)
        }
    }
}

#Preview("CCGlassCluster") {
    VStack(spacing: 24) {
        CCGlassCluster {
            CCDesigin.GlassIconButton(icon: "chat-plus") {}
            CCDesigin.GlassIconButton(icon: "three-dots-menu-horizontal") {}
        }
        CCGlassCluster(spacing: 4) {
            CCDesigin.GlassIconButton(icon: "layer-two") {}
            CCDesigin.GlassIconButton(icon: "user-plus") {}
            CCDesigin.GlassIconButton(icon: "filter-funnel") {}
        }
    }
    .padding(40)
    .background(Color.cc.background)
}

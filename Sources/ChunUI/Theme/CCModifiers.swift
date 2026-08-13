/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                         CCModifiers.swift                                  ║
 * ║                    统一 View 修饰符 API                                    ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: 依赖 SwiftUI View/Namespace、Color.cc 设计令牌、TimelineView 帧时钟
 * [OUTPUT]: 对外提供 CCGlassEffectContainer、ccGlassEffect/softGlassStyle、appleCard/ccGroupCard、shimmer（TimelineView 相位取模，禁 repeatForever）
 * [POS]: DesignSystem/Theme 的系统效果兼容边界；iOS 26 装配 Liquid Glass，iOS 18.6–25 统一降级为微拟物材质，业务层不得直接调用 glassEffect；循环光效一律时钟取模，禁止把相位写进动画事务
 *
 * API:
 *   .softGlassStyle()           // 圆形软玻璃 (CircleButton 同款)
 *   .softGlassStyle(.capsule)   // 胶囊软玻璃
 *   .softGlassStyle(.roundedRectangle(12)) // 连续圆角矩形软玻璃，iOS 26 直接传 shape 给 glassEffect
 *   .softGlassStyle(.unevenRoundedRectangle(topLeading: 24, bottomLeading: 12, bottomTrailing: 12, topTrailing: 24))
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 软玻璃形状
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum SoftGlassShape {
    case circle
    case capsule
    case roundedRectangle(CGFloat)
    /// 非对称圆角矩形 (topLeading, bottomLeading, bottomTrailing, topTrailing)
    case unevenRoundedRectangle(topLeading: CGFloat, bottomLeading: CGFloat, bottomTrailing: CGFloat, topTrailing: CGFloat)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Liquid Glass 容器兼容边界
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 共享玻璃采样容器：iOS 26 使用系统 GlassEffectContainer，旧系统保留原布局。
public struct CCGlassEffectContainer<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    @ViewBuilder
    public var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer {
                content()
            }
        } else {
            content()
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 软玻璃样式 (CircleButton 同款)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension View {
    /// Liquid Glass 唯一兼容出口。共享 id/namespace 在 iOS 26 启用原生形变，旧系统保留同形微拟物降级。
    @ViewBuilder
    public func ccGlassEffect(
        _ shape: SoftGlassShape = .circle,
        id: String? = nil,
        in namespace: Namespace.ID? = nil
    ) -> some View {
        if #available(iOS 26, *) {
            switch shape {
            case .circle:
                self.glassEffect(.regular.interactive(), in: Circle())
                    .ccGlassEffectID(id, in: namespace)
            case .capsule:
                self.glassEffect(.regular.interactive(), in: Capsule())
                    .ccGlassEffectID(id, in: namespace)
            case .roundedRectangle(let radius):
                self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .ccGlassEffectID(id, in: namespace)
            case .unevenRoundedRectangle(let tl, let bl, let br, let tr):
                self.glassEffect(
                    .regular.interactive(),
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: tl,
                        bottomLeadingRadius: bl,
                        bottomTrailingRadius: br,
                        topTrailingRadius: tr,
                        style: .continuous
                    )
                )
                .ccGlassEffectID(id, in: namespace)
            }
        } else {
            self.modifier(SoftGlassModifier(shape: shape))
        }
    }

    /// 软玻璃历史入口，内部统一收口到 ccGlassEffect。
    public func softGlassStyle(_ shape: SoftGlassShape = .circle) -> some View {
        ccGlassEffect(shape)
    }
}

@available(iOS 26, *)
private extension View {
    @ViewBuilder
    public func ccGlassEffectID(_ id: String?, in namespace: Namespace.ID?) -> some View {
        if let id, let namespace {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
    }
}

/// 微拟物软玻璃修饰符 (iOS 25-)
public struct SoftGlassModifier: ViewModifier {
    let shape: SoftGlassShape

    public func body(content: Content) -> some View {
        content
            .background(backgroundView)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch shape {
        case .circle:
            Circle()
                .fill(gradientFill)
                .overlay(Circle().stroke(strokeGradient, lineWidth: 1))
        case .capsule:
            Capsule()
                .fill(gradientFill)
                .overlay(Capsule().stroke(strokeGradient, lineWidth: 1))
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(gradientFill)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(strokeGradient, lineWidth: 1)
                )
        case .unevenRoundedRectangle(let tl, let bl, let br, let tr):
            UnevenRoundedRectangle(
                topLeadingRadius: tl,
                bottomLeadingRadius: bl,
                bottomTrailingRadius: br,
                topTrailingRadius: tr,
                style: .continuous
            )
            .fill(gradientFill)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: tl,
                    bottomLeadingRadius: bl,
                    bottomTrailingRadius: br,
                    topTrailingRadius: tr,
                    style: .continuous
                )
                .stroke(strokeGradient, lineWidth: 1)
            )
        }
    }

    private var gradientFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.cc.background,
                Color.cc.background.mix(with: .black, amount: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.5),
                Color.clear,
                Color.black.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Apple Card 样式
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension View {

    /// Apple Design 风格卡片
    public func appleCard(radius: CGFloat = 20) -> some View {
        self
            .background(Color.cc.background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.cc.background, lineWidth: 2)
                    .blendMode(.overlay)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.cc.foreground.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: Color.cc.shadow.opacity(0.08), radius: 6, y: 3)
            .shadow(color: Color.cc.shadow.opacity(0.12), radius: 16, y: 8)
    }

    /// 极简分组卡片 (设置页 / 信息页通用)
    /// card 底色用 shaped background（不 clip 内容），避免行内 CCCuteTag / 键帽阴影被父容器裁切
    /// - Parameter radius: 圆角 (默认 .cc.radiusCard = 16)
    public func ccGroupCard(radius: CGFloat = .cc.radiusCard) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.cc.card)
                    .shadow(color: Color.cc.shadow.opacity(0.05), radius: 12, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.cc.border.opacity(0.6), lineWidth: 0.5)
            }
    }

    /// 条件修饰符
    @ViewBuilder
    public func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// 循环扫光：相位由 TimelineView 时刻取模，父级动画事务杀不死、后台也不积压补播
    public func shimmer(active: Bool = true, duration: TimeInterval = 1.5) -> some View {
        self.modifier(ShimmerModifier(active: active, duration: duration))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 闪光修饰符（时钟取模，禁 repeatForever）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct ShimmerModifier: ViewModifier {
    public var active: Bool = true
    public var duration: TimeInterval = 1.5

    public func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    TimelineView(.animation(minimumInterval: nil, paused: !active)) { timeline in
                        let period = max(0.01, duration)
                        let progress = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: period) / period
                        let band = max(geo.size.width * 0.42, 72)
                        let travel = geo.size.width + band
                        let x = -band + CGFloat(progress) * travel

                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: band)
                        .offset(x: x)
                    }
                    // 时间相位禁入任何环境动画：暂停攒下的跨度一旦被插值，就是那阵爆燃补播
                    .transaction { $0.animation = nil }
                }
                .mask(content)
                .opacity(active ? 1 : 0)
                .allowsHitTesting(false)
            }
    }
}

/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                         CCModifiers.swift                                  ║
 * ║                    统一 View 修饰符 API                                    ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: 依赖 SwiftUI View/Namespace、Color.cc 设计令牌、TimelineView 帧时钟
 * [OUTPUT]: 对外提供 CCGlassEffectContainer、SoftGlassShape + SoftGlassPath（单一可动画几何类型：切形不换宿主身份）、ccGlassEffect/softGlassStyle、appleCard/ccGroupCard、shimmer（TimelineView 相位取模，禁 repeatForever）
 * [POS]: DesignSystem/Theme 的系统效果兼容边界；iOS 26 装配 Liquid Glass，iOS 18.6–25 统一降级为微拟物材质，业务层不得直接调用 glassEffect；玻璃形状一律经 SoftGlassPath 单一类型传入（@ViewBuilder 按 case 分支会让宿主切形时整棵子树重建——UITextView 焦点丢失、键盘二次弹出的根因）；循环光效一律时钟取模，禁止把相位写进动画事务
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
    /// 任意自定义轮廓（如 CCGlassPairShape 双圆融合）
    case custom(AnyShape)

    /// 统一成单一 Shape 类型：切换 case 不改变宿主视图身份（见 SoftGlassPath）
    var glassPath: SoftGlassPath {
        switch self {
        case .circle, .capsule:
            return SoftGlassPath(radius: SoftGlassPath.capsuleRadius)
        case .roundedRectangle(let radius):
            return SoftGlassPath(radius: radius)
        case .unevenRoundedRectangle(let tl, let bl, let br, let tr):
            return SoftGlassPath(topLeading: tl, bottomLeading: bl, bottomTrailing: br, topTrailing: tr)
        case .custom(let anyShape):
            return SoftGlassPath(custom: anyShape)
        }
    }
}

/// 软玻璃的唯一几何类型。
///
/// 为什么不能直接把 Capsule / RoundedRectangle 传给 glassEffect：`@ViewBuilder` 里按 case 分支会生成不同类型的
/// `_ConditionalContent`，宿主视图从胶囊切到圆角矩形的那一刻整棵子树被销毁重建——里面若有 UITextView，
/// 焦点丢失、键盘收起再弹（实锤：输入坞聚焦展开后键盘二次弹出）。这里所有形状都落成同一个 Shape 类型：
/// 四角半径可动画（AnimatableData），圆/胶囊用大半径在 path 时按短边一半夹住。
public struct SoftGlassPath: Shape {
    /// 圆 / 胶囊的哨兵半径：path 时按 min(w, h) / 2 夹住
    public static let capsuleRadius: CGFloat = 10_000

    public var topLeading: CGFloat
    public var bottomLeading: CGFloat
    public var bottomTrailing: CGFloat
    public var topTrailing: CGFloat
    private let custom: AnyShape?

    public init(radius: CGFloat) {
        self.init(topLeading: radius, bottomLeading: radius, bottomTrailing: radius, topTrailing: radius)
    }

    public init(topLeading: CGFloat, bottomLeading: CGFloat, bottomTrailing: CGFloat, topTrailing: CGFloat) {
        self.topLeading = topLeading
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
        self.topTrailing = topTrailing
        self.custom = nil
    }

    public init(custom: AnyShape) {
        self.topLeading = 0
        self.bottomLeading = 0
        self.bottomTrailing = 0
        self.topTrailing = 0
        self.custom = custom
    }

    public var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(topLeading, bottomLeading), AnimatablePair(bottomTrailing, topTrailing)) }
        set {
            topLeading = newValue.first.first
            bottomLeading = newValue.first.second
            bottomTrailing = newValue.second.first
            topTrailing = newValue.second.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        if let custom { return custom.path(in: rect) }
        let cap = min(rect.width, rect.height) / 2
        return UnevenRoundedRectangle(
            topLeadingRadius: min(topLeading, cap),
            bottomLeadingRadius: min(bottomLeading, cap),
            bottomTrailingRadius: min(bottomTrailing, cap),
            topTrailingRadius: min(topTrailing, cap),
            style: .continuous
        )
        .path(in: rect)
    }
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
            // 单一 Shape 类型：宿主在不同形状间切换不改身份，圆角随动画插值（禁回退成按 case 分支）
            self.glassEffect(.regular.interactive(), in: shape.glassPath)
                .ccGlassEffectID(id, in: namespace)
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

    /// 同一几何类型画底与描边：切形不换分支，圆角可动画
    private var backgroundView: some View {
        let path = shape.glassPath
        return path
            .fill(gradientFill)
            .overlay(path.stroke(strokeGradient, lineWidth: 1))
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

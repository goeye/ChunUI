/**
 * [INPUT]: 依赖 SwiftUI Shape/Path、ccGlassEffect(.custom) 自定义形状玻璃（iOS 26 glassEffect(in:) / 18.6–25 SoftGlassModifier）、EnvironmentValues
 * [OUTPUT]: 对外提供 CCGlassPair<Leading, Trailing>（并排两枚圆钮共用一块「液态融合」玻璃：两个完整圆 + 中间一段内凹腰身，圆钮各自轮廓仍清晰可辨，不是胶囊）、CCGlassPairShape（可复用的双圆融合形状）、ccGlassPairMember 环境值（成员放弃自描玻璃）
 * [POS]: Components 的并排玻璃钮唯一范式：两枚相邻 GlassIconButton/GlassIconButtonLabel 一律 CCGlassPair(leading:trailing:)——外部只传左右内容，融合背景由组件自绘并在全系统同形；GlassIconButtonLabel 读环境自动放弃自身玻璃；禁止业务页手排两枚独立玻璃圆钮，也禁止用胶囊/union 把两钮合成一个
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 环境值：成员是否在融合对里（在则不自描玻璃）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCGlassPairMemberKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// true = 处于 CCGlassPair 内：玻璃由对组件统一绘制，成员只出 icon 与命中区
    var ccGlassPairMember: Bool {
        get { self[CCGlassPairMemberKey.self] }
        set { self[CCGlassPairMemberKey.self] = newValue }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCGlassPairShape（双圆 + 内凹腰身的液态融合轮廓）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 两枚直径 d、间距 gap 的圆，在内侧以两段二次曲线连成一条收腰的桥——
/// 桥的起止点落在各圆上距竖直方向 `bridgeAngle` 处，腰身最窄处半高 = r × `waist`，
/// 圆的外侧轮廓完整保留，所以看起来是「两个圆互相吸住」，不是一颗药丸
public struct CCGlassPairShape: Shape {
    public var diameter: CGFloat
    public var gap: CGFloat
    /// 桥起止点距竖直方向的角度（度）：越大桥越低、圆越完整
    public var bridgeAngle: Double = 46
    /// 腰身最窄处半高相对半径的比例
    public var waist: CGFloat = 0.42

    public init(diameter: CGFloat, gap: CGFloat, bridgeAngle: Double = 46, waist: CGFloat = 0.42) {
        self.diameter = diameter
        self.gap = gap
        self.bridgeAngle = bridgeAngle
        self.waist = waist
    }

    public func path(in rect: CGRect) -> Path {
        let r = diameter / 2
        let a = CGPoint(x: rect.minX + r, y: rect.midY)
        let b = CGPoint(x: rect.minX + r + diameter + gap, y: rect.midY)
        let theta = bridgeAngle * .pi / 180
        let sx = r * sin(theta)
        let cy = r * cos(theta)
        let midX = (a.x + b.x) / 2
        // 腰身：桥的控制点拉向中线，最窄处半高 ≈ r × waist（二次曲线中点取控制点与端点的 1/2 混合）
        let waistHalf = r * waist
        let controlOffset = cy - (2 * waistHalf - cy)   // 使曲线中点 y = ±waistHalf

        let topA = CGPoint(x: a.x + sx, y: a.y - cy)
        let topB = CGPoint(x: b.x - sx, y: b.y - cy)
        let bottomA = CGPoint(x: a.x + sx, y: a.y + cy)
        let bottomB = CGPoint(x: b.x - sx, y: b.y + cy)

        var path = Path()
        path.move(to: topA)
        // 上桥：向中线内凹
        path.addQuadCurve(to: topB, control: CGPoint(x: midX, y: a.y - cy + controlOffset))
        // 右圆外侧：从上内点经右顶、右缘、右底到下内点（角度递增 = 屏幕顺时针）
        path.addArc(
            center: b,
            radius: r,
            startAngle: .degrees(-(90 + bridgeAngle)),
            endAngle: .degrees(90 + bridgeAngle),
            clockwise: false
        )
        // 下桥：向中线内凹
        path.addQuadCurve(to: bottomA, control: CGPoint(x: midX, y: a.y + cy - controlOffset))
        // 左圆外侧：从下内点经左底、左缘、左顶回到上内点
        path.addArc(
            center: a,
            radius: r,
            startAngle: .degrees(90 - bridgeAngle),
            endAngle: .degrees(270 + bridgeAngle),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCGlassPair（左右两枚圆钮 + 一块融合玻璃）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 并排两枚玻璃圆钮的唯一写法：外部传左右内容（GlassIconButton / Menu 的 GlassIconButtonLabel 皆可），
/// 组件按 GlassIconButtonMetrics.size 排位，并用 CCGlassPairShape 自绘一块融合玻璃；
/// iOS 26 走 glassEffect(in: 融合形状)，18.6–25 走同形软玻璃，成员在两套系统下都不自描
public struct CCGlassPair<Leading: View, Trailing: View>: View {
    private let size: CGFloat
    private let gap: CGFloat
    private let leading: () -> Leading
    private let trailing: () -> Trailing

    /// - Parameters:
    ///   - size: 单钮直径，默认 GlassIconButtonMetrics.size
    ///   - gap: 两圆间距，默认 6——够近到腰身像被吸住，又足够让两圆各自可辨
    public init(
        size: CGFloat = CCDesigin.GlassIconButtonMetrics.size,
        gap: CGFloat = 6,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.size = size
        self.gap = gap
        self.leading = leading
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: gap) {
            leading()
                .frame(width: size, height: size)
            trailing()
                .frame(width: size, height: size)
        }
        .environment(\.ccGlassPairMember, true)
        .ccGlassEffect(.custom(AnyShape(CCGlassPairShape(diameter: size, gap: gap))))
    }
}

#Preview("CCGlassPair") {
    VStack(spacing: 28) {
        CCGlassPair {
            CCDesigin.GlassIconButton(icon: "chat-plus") {}
        } trailing: {
            CCDesigin.GlassIconButton(icon: "three-dots-menu-horizontal") {}
        }
        CCGlassPairShape(diameter: 60, gap: 8)
            .fill(Color.cc.primary.opacity(0.25))
            .frame(width: 128, height: 60)
    }
    .padding(40)
    .background(Color.cc.background)
}

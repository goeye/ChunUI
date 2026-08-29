/**
 * [INPUT]: 依赖 ccGlassEffect(.capsule)（iOS 26 Liquid Glass / 18.6–25 软玻璃同形降级）、EnvironmentValues
 * [OUTPUT]: 对外提供 CCGlassPair<Leading, Trailing>（并排两枚圆钮共用一枚胶囊玻璃背景，成员不自描）与 ccGlassPairMember 环境值
 * [POS]: Components 的并排玻璃钮唯一范式：两枚相邻 GlassIconButton/GlassIconButtonLabel 一律 CCGlassPair(leading:trailing:)——外部只传左右内容，背景就是一枚胶囊，不做任何特殊形状；GlassIconButtonLabel 读环境自动放弃自身玻璃；禁止业务页手排两枚独立玻璃圆钮
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

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

/// 并排两枚玻璃圆钮的唯一写法：外部传左右内容（GlassIconButton / Menu 的 GlassIconButtonLabel 皆可），
/// 组件按 GlassIconButtonMetrics.size 排位，背景是一枚胶囊玻璃；成员在两套系统下都不自描
public struct CCGlassPair<Leading: View, Trailing: View>: View {
    private let size: CGFloat
    private let gap: CGFloat
    private let leading: () -> Leading
    private let trailing: () -> Trailing

    /// - Parameters:
    ///   - size: 单钮直径，默认 GlassIconButtonMetrics.size
    ///   - gap: 两钮间距，默认 2
    public init(
        size: CGFloat = CCDesigin.GlassIconButtonMetrics.size,
        gap: CGFloat = 2,
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
        .ccGlassEffect(.capsule)
    }
}

#Preview("CCGlassPair") {
    CCGlassPair {
        CCDesigin.GlassIconButton(icon: "chat-plus") {}
    } trailing: {
        CCDesigin.GlassIconButton(icon: "three-dots-menu-horizontal") {}
    }
    .padding(40)
    .background(Color.cc.background)
}

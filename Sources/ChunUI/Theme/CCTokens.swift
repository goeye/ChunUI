/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCTokens.swift                                    ║
 * ║                间距 / 圆角 / 阴影 / 动画 设计令牌                           ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: 语义化令牌名称
 * [OUTPUT]: CGFloat / Animation / Shadow 值
 * [POS]: DesignSystem/Theme - 设计令牌
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCSpacing 间距配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 间距配置（基于 4pt 网格）
public struct CCSpacing: Sendable {

    public var xs: CGFloat
    public var sm: CGFloat
    public var md: CGFloat
    public var base: CGFloat
    public var lg: CGFloat
    public var xl: CGFloat
    public var xxl: CGFloat
    public var xxxl: CGFloat
    public var pageHorizontal: CGFloat
    public var pageVertical: CGFloat
    public var cardPadding: CGFloat
    public var listItem: CGFloat
    public var section: CGFloat

    public init(
        xs: CGFloat = 4,
        sm: CGFloat = 8,
        md: CGFloat = 12,
        base: CGFloat = 16,
        lg: CGFloat = 20,
        xl: CGFloat = 24,
        xxl: CGFloat = 32,
        xxxl: CGFloat = 48,
        pageHorizontal: CGFloat = 16,
        pageVertical: CGFloat = 16,
        cardPadding: CGFloat = 16,
        listItem: CGFloat = 12,
        section: CGFloat = 24
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.base = base
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
        self.xxxl = xxxl
        self.pageHorizontal = pageHorizontal
        self.pageVertical = pageVertical
        self.cardPadding = cardPadding
        self.listItem = listItem
        self.section = section
    }

    public static let `default` = CCSpacing()
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCRadius 圆角配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCRadius: Sendable {

    public var none: CGFloat
    public var sm: CGFloat
    public var md: CGFloat
    public var base: CGFloat
    public var lg: CGFloat
    public var xl: CGFloat
    public var full: CGFloat
    public var button: CGFloat
    public var card: CGFloat
    public var input: CGFloat
    public var avatar: CGFloat

    public init(
        none: CGFloat = 0,
        sm: CGFloat = 4,
        md: CGFloat = 8,
        base: CGFloat = 12,
        lg: CGFloat = 16,
        xl: CGFloat = 24,
        full: CGFloat = 9999,
        button: CGFloat = 12,
        card: CGFloat = 16,
        input: CGFloat = 10,
        avatar: CGFloat = 9999
    ) {
        self.none = none
        self.sm = sm
        self.md = md
        self.base = base
        self.lg = lg
        self.xl = xl
        self.full = full
        self.button = button
        self.card = card
        self.input = input
        self.avatar = avatar
    }

    public static let `default` = CCRadius()
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCShadows 阴影配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCShadows: Sendable {

    public struct Shadow: Sendable {
        public var color: Color
        public var radius: CGFloat
        public var x: CGFloat
        public var y: CGFloat

        public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }

    public var sm: Shadow
    public var md: Shadow
    public var lg: Shadow
    public var xl: Shadow
    public var card: Shadow
    public var fab: Shadow
    public var modal: Shadow

    public init(
        sm: Shadow = Shadow(color: .black.opacity(0.05), radius: 2, y: 1),
        md: Shadow = Shadow(color: .black.opacity(0.1), radius: 4, y: 2),
        lg: Shadow = Shadow(color: .black.opacity(0.15), radius: 8, y: 4),
        xl: Shadow = Shadow(color: .black.opacity(0.2), radius: 16, y: 8),
        card: Shadow = Shadow(color: .black.opacity(0.08), radius: 6, y: 3),
        fab: Shadow = Shadow(color: .black.opacity(0.15), radius: 8, y: 4),
        modal: Shadow = Shadow(color: .black.opacity(0.25), radius: 24, y: 12)
    ) {
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.card = card
        self.fab = fab
        self.modal = modal
    }

    public static let `default` = CCShadows()

    public static let dark = CCShadows(
        sm: Shadow(color: .black.opacity(0.3), radius: 2, y: 1),
        md: Shadow(color: .black.opacity(0.4), radius: 4, y: 2),
        lg: Shadow(color: .black.opacity(0.5), radius: 8, y: 4),
        xl: Shadow(color: .black.opacity(0.6), radius: 16, y: 8),
        card: Shadow(color: .black.opacity(0.4), radius: 6, y: 3),
        fab: Shadow(color: .black.opacity(0.5), radius: 8, y: 4),
        modal: Shadow(color: .black.opacity(0.6), radius: 24, y: 12)
    )
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCAnimation 动画配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCAnimation: Sendable {

    public var fast: Double
    public var normal: Double
    public var slow: Double
    public var springDamping: Double
    public var springResponse: Double

    public init(
        fast: Double = 0.15,
        normal: Double = 0.25,
        slow: Double = 0.4,
        springDamping: Double = 0.7,
        springResponse: Double = 0.3
    ) {
        self.fast = fast
        self.normal = normal
        self.slow = slow
        self.springDamping = springDamping
        self.springResponse = springResponse
    }

    public static let `default` = CCAnimation()

    public var fastAnimation: Animation { .easeOut(duration: fast) }
    public var normalAnimation: Animation { .easeInOut(duration: normal) }
    public var slowAnimation: Animation { .easeInOut(duration: slow) }
    public var springAnimation: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 便捷访问 (.cc 命名空间)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CGFloat {
    public static var cc: CCSpacingAccessor { CCSpacingAccessor() }
}

public struct CCSpacingAccessor {
    private var spacing: CCSpacing { .default }
    private var radius: CCRadius { .default }

    // 间距
    public var xs: CGFloat { spacing.xs }
    public var sm: CGFloat { spacing.sm }
    public var md: CGFloat { spacing.md }
    public var base: CGFloat { spacing.base }
    public var lg: CGFloat { spacing.lg }
    public var xl: CGFloat { spacing.xl }
    public var xxl: CGFloat { spacing.xxl }
    public var xxxl: CGFloat { spacing.xxxl }
    public var page: CGFloat { spacing.pageHorizontal }
    public var card: CGFloat { spacing.cardPadding }

    /// 发丝线宽度 (分隔线 / 描边统一 0.5pt)
    public var hairline: CGFloat { 0.5 }

    // 圆角
    public var radiusSm: CGFloat { radius.sm }
    public var radiusMd: CGFloat { radius.md }
    public var radiusBase: CGFloat { radius.base }
    public var radiusLg: CGFloat { radius.lg }
    public var radiusXl: CGFloat { radius.xl }
    public var radiusButton: CGFloat { radius.button }
    public var radiusCard: CGFloat { radius.card }
    public var radiusInput: CGFloat { radius.input }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - View Shadow 扩展
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension View {
    public func ccShadow(_ shadow: CCShadows.Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    public func ccShadow(_ style: CCShadowStyle) -> some View {
        let shadows = CCShadows.default
        let shadow: CCShadows.Shadow
        switch style {
        case .sm: shadow = shadows.sm
        case .md: shadow = shadows.md
        case .lg: shadow = shadows.lg
        case .xl: shadow = shadows.xl
        case .card: shadow = shadows.card
        case .fab: shadow = shadows.fab
        case .modal: shadow = shadows.modal
        }
        return ccShadow(shadow)
    }
}

public enum CCShadowStyle {
    case sm, md, lg, xl
    case card, fab, modal
}

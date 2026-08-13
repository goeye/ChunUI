//
//  CCNeoButton.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Color.cc/Font.cc 设计令牌、Color.mix 拟物混色、PikaIcon
 * [OUTPUT]: 对外提供 CCNeoButton（primary/secondary/ghost/outline/danger 五变体 × small/medium/large；primary 可 accent 覆色；async loading + 弹簧按压）、CCNeoIconButton、CCNeoPressStyle、CCListRowPressStyle（列表行按压灰底）
 * [POS]: DesignSystem/Compents 的微拟物按钮族，移植 Laper Button 设计语言（上亮下暗微渐变 + 上光下影渐变发丝边 + 紧贴投影 + 按压弹簧 + Promise 自动 loading），供全应用统一使用；阴影全族收束为 radius 3 以内的贴地影，质感由边而非影承担
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 变体 / 尺寸
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCNeoVariant {
    case primary    // 主题色实底：上亮下暗微渐变 + 顶部内高光
    case secondary  // 卡片底 + 发丝边 + 极柔阴影
    case ghost      // 无底无边，按压显灰阶
    case outline    // 描边，按压转主题色
    case danger     // 危险红实底
}

public enum CCNeoSize {
    case small      // h34 footnote
    case medium     // h44 body
    case large      // h52 bodyBold

    var height: CGFloat {
        switch self {
        case .small: return 34
        case .medium: return 44
        case .large: return 52
        }
    }

    var font: Font {
        switch self {
        case .small: return .cc.footnote
        case .medium: return .cc.callout
        case .large: return .cc.bodyBold
        }
    }

    var hPadding: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 22
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCNeoButton
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 微拟物按钮：async action 返回前自动进入 loading（Laper Promise 托管移植）
public struct CCNeoButton: View {
    let title: String
    var variant: CCNeoVariant = .primary
    var size: CCNeoSize = .medium
    var icon: String? = nil          // pika 图标名，置于文字左侧
    var fullWidth: Bool = false
    var disabled: Bool = false
    /// primary 覆色（如微信绿）；nil 走主题 primary
    var accent: Color? = nil
    var action: () async -> Void

    public init(
        _ title: String,
        variant: CCNeoVariant = .primary,
        size: CCNeoSize = .medium,
        icon: String? = nil,
        fullWidth: Bool = false,
        disabled: Bool = false,
        accent: Color? = nil,
        action: @escaping () async -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.fullWidth = fullWidth
        self.disabled = disabled
        self.accent = accent
        self.action = action
    }

    @State private var isLoading = false
    @State private var isPressed = false

    private var isDisabled: Bool { disabled || isLoading }
    private var fillColor: Color { accent ?? Color.cc.primary }

    /// 全按钮唯一形状事实源（背景/描边/裁切共用）
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size.height * 0.38, style: .continuous)
    }

    public var body: some View {
        Button {
            guard !isDisabled else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            CCTrack.onTap("neo:" + title)
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            HStack(spacing: 7) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foreground))
                        .scaleEffect(0.72)
                } else if let icon {
                    PikaIcon(icon, size: size.iconSize, color: foreground)
                }
                Text(title)
                    .font(size.font)
                    .fontWeight(variant == .primary || variant == .danger ? .semibold : .medium)
                    .foregroundStyle(foreground)
                    .lineLimit(1)
            }
            .padding(.horizontal, size.hPadding)
            .frame(height: size.height)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(backgroundLayer)
            .clipShape(shape)
            .overlay(borderLayer)
            .compositingGroup()
            .shadow(color: shadowColor, radius: 3, x: 0, y: 1.5)
            .opacity(isDisabled && !isLoading ? 0.45 : 1)
        }
        .buttonStyle(CCNeoPressStyle())
        .disabled(isDisabled)
    }

    // ━━━ 变体外观 ━━━

    private var foreground: Color {
        switch variant {
        case .primary: return accent != nil ? .white : .cc.primaryForeground
        case .danger: return .white
        case .secondary, .ghost: return .cc.foreground
        case .outline: return .cc.foreground
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch variant {
        case .primary:
            shape.fill(
                LinearGradient(
                    colors: [
                        fillColor.mix(with: .white, amount: 0.14),
                        fillColor,
                        fillColor.mix(with: .black, amount: 0.10),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(.inner(color: .white.opacity(0.42), radius: 1.5, x: 0, y: 1.5))
            )
        case .danger:
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.cc.destructive.mix(with: .white, amount: 0.12),
                        Color.cc.destructive,
                        Color.cc.destructive.mix(with: .black, amount: 0.12),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(.inner(color: .white.opacity(0.35), radius: 1.5, x: 0, y: 1.5))
            )
        case .secondary:
            shape.fill(Color.cc.card)
        case .ghost, .outline:
            shape.fill(Color.clear)
        }
    }

    /// 淡边质感：实底用「上光下影」渐变发丝边勾勒体积，平底用中性发丝边定义边界
    @ViewBuilder
    private var borderLayer: some View {
        switch variant {
        case .primary:
            shape.strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.45),
                        fillColor.mix(with: .black, amount: 0.28).opacity(0.55),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.66
            )
        case .danger:
            shape.strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.4),
                        Color.cc.destructive.mix(with: .black, amount: 0.3).opacity(0.55),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.66
            )
        case .secondary:
            shape.strokeBorder(Color.cc.border.opacity(0.9), lineWidth: CGFloat.cc.hairline)
        case .outline:
            shape.strokeBorder(Color.cc.border, lineWidth: 1)
        case .ghost:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary: return fillColor.opacity(0.2)
        case .danger: return Color.cc.destructive.opacity(0.18)
        case .secondary: return Color.cc.shadow.opacity(0.05)
        case .ghost, .outline: return .clear
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCNeoIconButton（图标变体：方形按压区 + 可选 secondary 底）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 图标按钮的纯视觉标签（无 Button 语义），供 CCNeoIconButton 与 Menu label 共用
public struct CCNeoIconLabel: View {
    let icon: String
    var diameter: CGFloat = 40
    var iconSize: CGFloat = 18
    var tint: Color = .cc.mutedForeground
    var filled: Bool = false          // true = secondary 卡片底，false = ghost

    public var body: some View {
        PikaIcon(icon, size: iconSize, color: tint)
            .frame(width: diameter, height: diameter)
            .background {
                if filled {
                    Circle()
                        .fill(Color.cc.card)
                        .overlay(Circle().strokeBorder(Color.cc.border.opacity(0.9), lineWidth: CGFloat.cc.hairline))
                        .shadow(color: Color.cc.shadow.opacity(0.05), radius: 3, x: 0, y: 1)
                }
            }
            .contentShape(Circle())
    }
}

public struct CCNeoIconButton: View {
    let icon: String
    var diameter: CGFloat = 40
    var iconSize: CGFloat = 18
    var tint: Color = .cc.mutedForeground
    var filled: Bool = false          // true = secondary 卡片底，false = ghost
    var action: () -> Void

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            CCNeoIconLabel(icon: icon, diameter: diameter, iconSize: iconSize, tint: tint, filled: filled)
        }
        .buttonStyle(CCNeoPressStyle())
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 按压弹簧（全族统一手感：0.97 缩放 + 弹簧回弹）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCNeoPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

/// 列表行按压：轻微灰底，给对象/往来/我的等 row 点击感知（不做缩放，避免与卡片布局抢戏）
public struct CCListRowPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.cc.muted.opacity(0.55)
                    : Color.clear
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 14) {
        CCNeoButton("和顾问聊聊 ta", variant: .primary, size: .large, icon: "sparkle-ai01", fullWidth: true) {}
        CCNeoButton("查看档案", variant: .secondary, size: .medium, icon: "user-love-heart") {}
        CCNeoButton("幽灵按钮", variant: .ghost, size: .medium) {}
        CCNeoButton("描边按钮", variant: .outline, size: .small) {}
        CCNeoButton("删除", variant: .danger, size: .small, icon: "delete-dustbin01") {}
        HStack {
            CCNeoIconButton(icon: "grid-dashboard01") {}
            CCNeoIconButton(icon: "layer-two", filled: true) {}
        }
    }
    .padding(24)
    .background(Color.cc.background)
}

/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCButtons.swift                                  ║
 * ║                       统一按钮组件库                                        ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: 设计系统颜色、SwiftUI、AppHelper (震动反馈)、PikaIcon 模板图标、shimmer（TimelineView 扫光）
 * [OUTPUT]: Button (统一), CCTagButton, GlassIconButton/CircleButton 正圆液态玻璃按钮（regular 50·24 / small 34·16）, 返回按钮
 * [POS]: DesignSystem/Compents 按钮组件，被业务视图消费；loading 扫光走 shimmer 时钟取模，禁止 Pow repeat(.shine) 积压补播
 *
 * API:
 *   CCDesigin.Button("文字", icon: nil, size: .large/.medium/.small, variant: .primary/.secondary, enable: true) { }
 *
 * 设计规范 (Figma 精准复刻):
 * 1. Primary: 霓虹粉玻璃质感 - 8层内阴影叠加 (primary 色 #ff00c8)
 * 2. Secondary: 柔和微拟物 (斜向渐变 + 简单内高光)
 * 3. 交互: 按下 scale(0.97)
 * 4. iOS 26+: Secondary 使用 Liquid Glass
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Pow
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 霓虹粉玻璃按钮样式 (Primary)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 霓虹粉玻璃按钮样式 - ZStack 多层叠加
/// 粉色底、白字、基于 primary 色推算高光阴影
public struct PinkGlassButtonStyle: ViewModifier {
    let enable: Bool

    /// 按钮主色 - 使用设计系统的 primary (霓虹粉 #ff00c8)
    private var buttonColor: Color { .cc.primary }

    public func body(content: Content) -> some View {
        content
            .background(backgroundLayer)
            .clipShape(Capsule())
            .overlay(innerShadowLayers)
            .overlay(borderLayer)
            .shadow(color: buttonColor.opacity(enable ? 0.4 : 0), radius: 8, x: 0, y: 4)
            .opacity(enable ? 1 : 0.5)
    }

    // ━━━ Layer 1: 背景渐变 (基于 foreground 色) ━━━
    private var backgroundLayer: some View {
        LinearGradient(
            stops: [
                .init(color: buttonColor.mix(with: .white, amount: 0.15), location: 0),
                .init(color: buttonColor, location: 0.5),
                .init(color: buttonColor.mix(with: .black, amount: 0.15), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // ━━━ Layer 2: 边框 ━━━
    private var borderLayer: some View {
        Capsule()
            .stroke(buttonColor.mix(with: .black, amount: 0.2), lineWidth: 0.5)
    }

    // ━━━ Layer 3-8: 多层内阴影叠加 ━━━
    private var innerShadowLayers: some View {
        ZStack {
            // Layer 3: 内边缘暗色轮廓
            Capsule()
                .stroke(buttonColor.mix(with: .black, amount: 0.3), lineWidth: 1)
                .blur(radius: 0.5)
                .clipShape(Capsule())

            // Layer 4: 顶部高光条
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.2), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1.5
                )
                .blur(radius: 0.5)
                .clipShape(Capsule())

            // Layer 5: 整体内阴影
            Capsule()
                .stroke(buttonColor.mix(with: .black, amount: 0.25), lineWidth: 2)
                .blur(radius: 2)
                .clipShape(Capsule())

            // Layer 6: 底部暗边
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [Color.clear, Color.clear, Color.black.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .blur(radius: 1)
                .clipShape(Capsule())

            // Layer 7: 底部冷色反光
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [Color.clear, Color.clear, buttonColor.mix(with: .white, amount: 0.3).opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .blur(radius: 1.5)
                .clipShape(Capsule())
        }
    }
}

extension View {
    /// 应用黑色玻璃按钮样式 (primary)
    public func pinkGlassButtonStyle(enable: Bool = true) -> some View {
        modifier(PinkGlassButtonStyle(enable: enable))
    }
}

/// 柔和微拟物样式 (secondary / 浅色按钮)
public struct SoftButtonStyle: ViewModifier {
    let backgroundColor: Color

    public func body(content: Content) -> some View {
        content
            .background(softGradient)
            .clipShape(Capsule())
            .overlay(innerHighlight)
            .shadow(color: Color.white.opacity(0.4), radius: 2, x: -1, y: -1)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 1, y: 1)
    }

    private var softGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: backgroundColor.mix(with: .white, amount: 0.05), location: 0),
                .init(color: backgroundColor, location: 0.3),
                .init(color: backgroundColor.mix(with: .black, amount: 0.08), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var innerHighlight: some View {
        Capsule()
            .stroke(
                LinearGradient(
                    colors: [Color.white.opacity(0.5), Color.clear, Color.black.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .blur(radius: 0.5)
    }
}

extension View {
    /// 应用柔和微拟物样式 (secondary)
    public func softButtonStyle(backgroundColor: Color) -> some View {
        modifier(SoftButtonStyle(backgroundColor: backgroundColor))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 基础按钮包装器
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 基础按钮包装器 - label 接收 isLoading 状态
    struct CCButton<Content>: View where Content: View {
        var enable: Bool
        var action: () async -> Void
        var label: (Bool) -> Content  // 传入 isLoading
        @State var onTap: Bool = false
        @State var shake: Int = 0
        @State var isLoading: Bool = false

        public init(enable: Bool = true, action: @MainActor @escaping () async -> Void, @ViewBuilder label: @escaping (Bool) -> Content) {
            self.enable = enable
            self.action = action
            self.label = label
        }

        /// 兼容旧 API: 无参数 label
        public init(enable: Bool = true, action: @MainActor @escaping () async -> Void, @ViewBuilder label: @escaping () -> Content) {
            self.enable = enable
            self.action = action
            self.label = { _ in label() }
        }

        public var body: some View {
            label(isLoading)
                .opacity(isLoading ? 0.6 : 1)
                // ━━━ 按压缩放效果 ━━━
                .scaleEffect(onTap ? 0.97 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: onTap)
                ._onButtonGesture {
                    guard isLoading == false else { return }
                    onTap = $0
                } perform: {
                    Task {
                        guard !isLoading else { return }
                        guard enable else {
                            shake += 1
                            AppHelper.shared.mada(.error)
                            return
                        }
                        AppHelper.shared.mada(.soft)
                        self.isLoading = true
                        await action()
                        self.isLoading = false
                    }
                }
                .shimmer(active: isLoading, duration: 0.8)
                .conditionalEffect(.repeat(.glow(color: Color.cc.background), every: 0.6), condition: self.isLoading)
                .changeEffect(.glow(color: Color.cc.background), value: self.onTap)
                .changeEffect(.shake(rate: .fast), value: shake)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 按钮尺寸 & 变体
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 按钮尺寸
    enum ButtonSize {
        case large   // 大按钮 (height 58)
        case medium  // 中按钮 (height 46)
        case small   // 小按钮 (height 38)
    }

    /// 按钮变体
    enum ButtonVariant {
        case primary    // 主要: 粉色玻璃质感
        case secondary  // 次要: 柔和微拟物
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 统一按钮组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 统一按钮组件 - isLoading 自动管理
    ///
    /// ```swift
    /// // 大按钮 (主要) - 粉色玻璃、黑字
    /// CCDesigin.Button("开始体验") { await doSomething() }
    ///
    /// // 中按钮 (次要) - async action 执行时自动显示 loading
    /// CCDesigin.Button("取消", size: .medium, variant: .secondary) { await cancel() }
    ///
    /// // 禁用态
    /// CCDesigin.Button("处理中...", enable: false) { }
    /// ```
    struct Button: View {
        let text: String
        let icon: String?
        let size: ButtonSize
        let variant: ButtonVariant
        let enable: Bool
        let action: () async -> Void

        public init(
            _ text: String,
            icon: String? = nil,
            size: ButtonSize = .large,
            variant: ButtonVariant = .primary,
            enable: Bool = true,
            action: @escaping () async -> Void = {}
        ) {
            self.text = text
            self.icon = icon
            self.size = size
            self.variant = variant
            self.enable = enable
            self.action = action
        }

        public var body: some View {
            CCButton(enable: enable) {
                CCTrack.onTap("btn:" + text)
                await action()
            } label: { isLoading in
                buttonLabel(isLoading: isLoading)
            }
        }

        @ViewBuilder
        private func buttonLabel(isLoading: Bool) -> some View {
            if #available(iOS 26, *), variant == .secondary {
                // iOS 26 secondary: Liquid Glass
                secondaryTextContent(isLoading: isLoading)
                    .contentShape(Capsule())
                    .containerShape(Capsule())
                    .glassEffect()
            } else if variant == .primary {
                // Primary: 黑色玻璃、白字
                primaryTextContent(isLoading: isLoading)
                    .pinkGlassButtonStyle(enable: enable)
            } else {
                // Secondary: 微拟物
                secondaryTextContent(isLoading: isLoading)
                    .softButtonStyle(backgroundColor: size == .small ? .cc.background : .cc.muted)
            }
        }

        // ━━━ 字体：small 用 subheadlineBold，其他用 bodyBold ━━━
        private var buttonFont: Font {
            size == .small ? .cc.subheadlineBold : .cc.bodyBold
        }

        // ━━━ Primary 文字 (白字) ━━━
        private func primaryTextContent(isLoading: Bool) -> some View {
            HStack(alignment: .center, spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(enable ? Color.cc.primaryForeground : .cc.mutedForeground)
                } else {
                    if size == .small, let icon {
                        CCDesigin.ICON(imageName: icon, size: 24, color: enable ? .cc.primaryForeground : .cc.mutedForeground)
                    }
                    if !text.isEmpty {
                        Text(text)
                            .font(buttonFont)
                            .foregroundStyle(enable ? Color.cc.primaryForeground : .cc.mutedForeground)
                    }
                }
            }
            .when(size != .small) { $0.frame(maxWidth: .infinity, alignment: .center) }
            .padding(.horizontal, size == .small ? 14 : 0)
            .frame(height: size == .large ? 58 : (size == .medium ? 48 : 38))
        }

        // ━━━ Secondary 文字 ━━━
        private func secondaryTextContent(isLoading: Bool) -> some View {
            HStack(alignment: .center, spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(enable ? Color.cc.foreground : .cc.mutedForeground)
                } else {
                    if size == .small, let icon {
                        CCDesigin.ICON(imageName: icon, size: 24, color: enable ? .cc.foreground : .cc.mutedForeground)
                    }
                    if !text.isEmpty {
                        Text(text)
                            .ccText(font: buttonFont, color: enable ? .cc.foreground : .cc.mutedForeground)
                    }
                }
            }
            .when(size != .small) { $0.frame(maxWidth: .infinity, alignment: .center) }
            .padding(.horizontal, size == .small ? 14 : 0)
            .frame(height: size == .large ? 58 : (size == .medium ? 48 : 38))
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 微拟物标签按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCTagButton: View {
        let icon: String
        let text: String
        var action: () async -> Void

        public init(icon: String, text: String, action: @escaping () async -> Void) {
            self.icon = icon
            self.text = text
            self.action = action
        }

        public var body: some View {
            CCDesigin.CCButton {
                await action()
            } label: {
                buttonContent
            }
        }

        @ViewBuilder
        private var buttonContent: some View {
            if #available(iOS 26, *) {
                // ━━━ iOS 26: Liquid Glass ━━━
                HStack(alignment: .center, spacing: 4) {
                    CCDesigin.ICON(imageName: self.icon, size: 16, color: .cc.mutedForeground)
                    Text(self.text)
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                }
                .padding(.all, 4)
                .padding(.leading, 4)
                .padding(.trailing, 6)
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .containerShape(RoundedRectangle(cornerRadius: 6))
                .glassEffect()
            } else {
                // ━━━ iOS 25-: 微拟物效果 ━━━
                HStack(alignment: .center, spacing: 4) {
                    CCDesigin.ICON(imageName: self.icon, size: 16, color: .cc.mutedForeground)
                    Text(self.text)
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                }
                .padding(.all, 4)
                .padding(.leading, 4)
                .padding(.trailing, 6)
                // ━━━ 微拟物渐变背景 ━━━
                .background(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.cc.background, location: 0),
                            .init(color: Color.cc.background.mix(with: .black, amount: 0.05), location: 0.5),
                            .init(color: Color.cc.background.mix(with: .black, amount: 0.10), location: 1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                // ━━━ 内高光 + 暗边 ━━━
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.clear,
                                    Color.black.opacity(0.08)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                // ━━━ 外阴影 ━━━
                .shadow(color: Color.cc.shadow.opacity(0.08), radius: 4, x: 0, y: 1)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 微拟物圆形按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    public enum GlassIconButtonMetrics {
        public static let size: CGFloat = 50
        /// 与 MainTabbar 图标同规（24pt）
        public static let iconSize: CGFloat = 24
        static let cornerRadius: CGFloat = 25
    }

    enum GlassIconButtonSize {
        case regular
        case small

        var side: CGFloat {
            switch self {
            case .regular: return GlassIconButtonMetrics.size
            case .small: return 34
            }
        }

        var icon: CGFloat {
            switch self {
            case .regular: return GlassIconButtonMetrics.iconSize
            // 小钮按直径比例缩 icon（34/50 × 24 ≈ 16），避免一刀切撑满
            case .small: return 16
            }
        }
    }

    /// 全局液态玻璃图标按钮：正圆；regular 内 icon 24 / small 内 icon 16
    struct GlassIconButton: View {
        let icon: String
        var tint: Color = .cc.foreground
        var size: GlassIconButtonSize = .regular
        var action: () -> Void

        public init(icon: String, tint: Color = .cc.foreground, size: GlassIconButtonSize = .regular, action: @escaping () -> Void = {}) {
            self.icon = icon
            self.tint = tint
            self.size = size
            self.action = action
        }

        public var body: some View {
            CCButton {
                CCTrack.onTap("glass:" + icon)
                action()
            } label: {
                GlassIconButtonLabel(icon: icon, tint: tint, size: size)
            }
        }
    }

    struct GlassIconButtonLabel: View {
        let icon: String
        var tint: Color = .cc.foreground
        var size: GlassIconButtonSize = .regular

        public init(icon: String, tint: Color = .cc.foreground, size: GlassIconButtonSize = .regular) {
            self.icon = icon
            self.tint = tint
            self.size = size
        }

        public var body: some View {
            PikaIcon(icon, size: size.icon, color: tint)
                .frame(width: size.side, height: size.side)
                .contentShape(Circle())
                .softGlassStyle(.circle)
        }
    }

    /// CircleButton 的纯展示 Label (用于 Menu 等需要自定义触发的场景)
    struct CircleButtonLabel: View {
        let icon: String

        public var body: some View {
            GlassIconButtonLabel(icon: icon)
        }
    }

    struct CircleButton: View {
        let icon: String
        let action: () async -> Void

        public init(icon: String, action: @escaping () async -> Void = {}) {
            self.icon = icon
            self.action = action
        }

        public var body: some View {
            CCButton {
                CCTrack.onTap("circle:" + icon)
                await action()
            } label: {
                CircleButtonLabel(icon: icon)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 胶囊返回按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CircularBackButton: View {
        var action: (() -> Void)?
        var autoLayout: Bool

        private let size = GlassIconButtonMetrics.size

        public init(autoLayout: Bool = true, action: (() -> Void)? = nil) {
            self.autoLayout = autoLayout
            self.action = action
        }

        public var body: some View {
            if autoLayout {
                VStack {
                    Spacer()
                    HStack {
                        button
                            .padding(.leading, 16)
                        Spacer()
                    }
                }
            } else {
                button
            }
        }

        private var button: some View {
            CCButton {
                if let action {
                    action()
                } else {
                    CCNav.pop()
                }
            } label: {
                buttonContent
            }
        }

        @ViewBuilder
        private var buttonContent: some View {
            if #available(iOS 26, *) {
                // ━━━ iOS 26: 原生 Liquid Glass ━━━
                Image("pika/arrow-left", bundle: .module)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: GlassIconButtonMetrics.iconSize, height: GlassIconButtonMetrics.iconSize)
                    .foregroundStyle(Color.cc.foreground)
                    .frame(width: size, height: size)
                    .contentShape(Circle())
                    .containerShape(Circle())
                    .glassEffect(.regular.interactive(), in: Circle())
            } else {
                // ━━━ iOS 25-: 微拟物效果 ━━━
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.cc.background.opacity(0.95), location: 0),
                                .init(color: Color.cc.background.mix(with: .black, amount: 0.05).opacity(0.95), location: 0.5),
                                .init(color: Color.cc.background.mix(with: .black, amount: 0.12).opacity(0.95), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    // ━━━ 内高光 + 暗边 ━━━
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear,
                                        Color.black.opacity(0.08)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .overlay {
                        CCDesigin.ICON(imageName: "arrow-left", size: GlassIconButtonMetrics.iconSize, color: .cc.foreground)
                    }
                    // ━━━ 外阴影 ━━━
                    .shadow(color: Color.cc.shadow.opacity(0.08), radius: 6, x: 0, y: 2)
                    .shadow(color: Color.cc.shadow.opacity(0.12), radius: 12, x: 0, y: 4)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - TabBar 风格返回按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct TabBarStyleBackButton: View {
        var action: (() -> Void)?
        var size: CGFloat

        public init(size: CGFloat = CCDesigin.GlassIconButtonMetrics.size, action: (() -> Void)? = nil) {
            self.size = size
            self.action = action
        }

        public var body: some View {
            CCButton {
                if let action {
                    action()
                } else {
                    CCNav.pop()
                }
            } label: {
                buttonContent
            }
        }

        @ViewBuilder
        private var buttonContent: some View {
            if #available(iOS 26, *) {
                // ━━━ iOS 26: Liquid Glass ━━━
                CCDesigin.ICON(imageName: "arrow-left", size: 16, color: .cc.foreground)
                    .frame(width: size, height: size)
                    .contentShape(Circle())
                    .containerShape(Circle())
                    .glassEffect(.regular.interactive(), in: Circle())
            } else {
                // ━━━ iOS 25-: 微拟物效果 ━━━
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.cc.background.opacity(0.95), location: 0),
                                .init(color: Color.cc.background.mix(with: .black, amount: 0.05).opacity(0.95), location: 0.5),
                                .init(color: Color.cc.background.mix(with: .black, amount: 0.12).opacity(0.95), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    // ━━━ 内高光 + 暗边 ━━━
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.35),
                                        Color.clear,
                                        Color.black.opacity(0.08)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .overlay {
                        CCDesigin.ICON(imageName: "arrow-left", size: 16, color: .cc.foreground)
                    }
                    // ━━━ 外阴影 ━━━
                    .shadow(color: Color.cc.shadow.opacity(0.08), radius: 4, x: 0, y: 1)
                    .shadow(color: Color.cc.shadow.opacity(0.06), radius: 8, x: 0, y: 3)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 返回按钮 View Modifier
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    /// 为视图添加左下角返回按钮
    /// - Parameter action: 自定义返回动作，nil 时使用默认 pop
    func withBackButton(action: (() -> Void)? = nil) -> some View {
        self.overlay(alignment: .bottomLeading) {
            CCDesigin.CircularBackButton(autoLayout: false, action: action)
                .padding(.leading, 16)
        }
    }
}

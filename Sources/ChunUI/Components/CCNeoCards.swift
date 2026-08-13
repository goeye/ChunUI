//
//  CCNeoCards.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Color.cc 设计令牌与 CGFloat.cc.hairline、PikaIcon
 * [OUTPUT]: 对外提供 CCAppleCard 卡片容器（连续圆角 + 发丝边 + 三级软阴影，移植 Laper AppleCard）、CCNeoInput 微拟物输入框（焦点环）与 CCCuteTag 统计胶囊（1:1 移植 Laper CuteTag：24pt 不透明胶囊 + 1px 边 + 贴地微影 + 12pt 图标，严禁 blur）
 * [POS]: DesignSystem/Compents 的微拟物容器/表单族，与 CCNeoButton 同一设计语言，供卡片与表单场景统一使用
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCAppleCard（Laper AppleCard 移植：连续圆角 + 发丝边 + 分级阴影）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCAppleCard<Content: View>: View {
    var radius: CGFloat = 28
    var shadowLevel: Int = 1          // 1 极柔 / 2 中 / 3 抬升（拖拽态）
    var border: Bool = true
    @ViewBuilder var content: () -> Content

    public init(radius: CGFloat = 28, shadowLevel: Int = 1, border: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.radius = radius
        self.shadowLevel = shadowLevel
        self.border = border
        self.content = content
    }

    private var shadow: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch shadowLevel {
        case 3: return (0.18, 24, 12)
        case 2: return (0.12, 14, 6)
        default: return (0.07, 8, 3)
        }
    }

    public var body: some View {
        content()
            .background(Color.cc.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                if border {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.cc.border.opacity(0.6), lineWidth: CGFloat.cc.hairline)
                }
            }
            .shadow(color: Color.cc.shadow.opacity(shadow.opacity), radius: shadow.radius, x: 0, y: shadow.y)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCNeoInput（微拟物输入框：卡片底 + 发丝边 + 主题色焦点环）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCNeoInput: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    public init(placeholder: String, text: Binding<String>, icon: String? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
    }

    @FocusState private var focused: Bool

    public var body: some View {
        HStack(spacing: 10) {
            if let icon {
                PikaIcon(icon, size: 16, color: .cc.mutedForeground)
            }
            TextField(placeholder, text: $text)
                .font(Font.cc.body)
                .foregroundStyle(Color.cc.foreground)
                .tint(Color.cc.primary)
                .focused($focused)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.cc.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    focused ? Color.cc.primary.opacity(0.7) : Color.cc.border.opacity(0.7),
                    lineWidth: focused ? 1.2 : CGFloat.cc.hairline
                )
        }
        .background {
            // 焦点环：聚焦时主题色柔光外扩
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)
                .shadow(color: Color.cc.primary.opacity(focused ? 0.22 : 0), radius: 6)
        }
        .animation(.easeInOut(duration: 0.16), value: focused)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCCuteTag（Laper CuteTag 移植：24pt 不透明胶囊 + 1px 边 + 微影，禁 blur）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 统计胶囊：不透明底（大量同屏时零 blur 开销），图标 12pt 距文字 6pt，横排间距 4pt 由使用方控制
public struct CCCuteTag: View {
    let icon: String?
    let text: String

    public init(_ text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 6) {
            if let icon {
                PikaIcon(icon, size: 12, color: .cc.foreground)
            }
            Text(text)
                .ccText(font: .cc.caption, color: .cc.foreground)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .frame(height: 24)
        .background(Color.cc.background, in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.cc.border.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: Color.cc.shadow.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 18) {
        CCAppleCard {
            Text("AppleCard 容器")
                .padding(28)
                .frame(maxWidth: .infinity)
        }
        CCNeoInput(placeholder: "她叫什么名字？", text: .constant(""), icon: "user-love-heart")
        HStack(spacing: 4) {
            CCCuteTag("3 次约会", icon: "calendar-check")
            CCCuteTag("28 岁", icon: "user-default")
        }
    }
    .padding(24)
    .background(Color.cc.background)
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCKeycapTag（Laper admin Badge 键帽 1:1：彩色键面 + 顶面蚀刻高光 + 3px 厚底边）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCKeycapTag: View {
    let text: String
    var color: Color = .cc.primary
    var icon: String? = nil

    public init(_ text: String, color: Color = .cc.primary, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    /// 键帽文字：badge 色 76% 混前景（Laper color-mix 口径）
    private var textColor: Color {
        color.mix(with: Color.cc.foreground, amount: 0.24)
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                PikaIcon(icon, size: 12, color: textColor)
            }
            Text(text)
                .ccText(font: .cc.smBold, color: textColor)
                // 文字蚀刻：0 1 0 顶面高光
                .shadow(color: .white.opacity(0.52), radius: 0, x: 0, y: 1)
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(
            // 键面：badge 色 24%→34% 垂直渐变（card → muted 基底）
            LinearGradient(
                colors: [
                    color.mix(with: Color.cc.card, amount: 0.76),
                    color.mix(with: Color.cc.muted, amount: 0.66),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(color.mix(with: Color.cc.border, amount: 0.52), lineWidth: 1)
        }
        .overlay(alignment: .top) {
            // inset 0 1 0 顶面蚀刻高光
            Capsule()
                .fill(.white.opacity(0.52))
                .frame(height: 1)
                .padding(.horizontal, 3)
                .padding(.top, 1)
        }
        .background(
            // 3px 厚底边：键座下沉 2pt 露出
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color.mix(with: Color.cc.border, amount: 0.28))
                .offset(y: 2)
        )
        .padding(.bottom, 2)
        .fixedSize()
    }
}

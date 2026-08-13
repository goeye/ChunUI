//
//  CCSettingRow.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 PikaIcon 的模板矢量图标、Color.cc.* 语义色、Font.cc.* 排版
 * [OUTPUT]: 对外提供 CCSettingRow（极简设置行，支持 chevron/PRO/红点/文字/纯值尾随）、CCProTag（PRO 粉标签）、CCQuickAction（四宫格快捷动作）
 * [POS]: DesignSystem/Compents 的设置页原子组件，被 Features/Profile 的 ProfileView 消费，替代浮夸行样式
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCProTag (PRO 粉标签，黑白粉唯一彩色点缀)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// PRO 会员标签：品牌粉底 + 白字胶囊，是设置页里唯一允许出现的彩色元素
public struct CCProTag: View {
    public var text: String

    public init(_ text: String = "PRO") {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.cc.smBold)
            .tracking(0.5)
            .foregroundStyle(Color.cc.primaryForeground)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.cc.primary, in: Capsule())
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCSettingRow (极简设置行：图标 + 标题 + 尾随)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 极简设置行 —— 纯展示，点击交互由外层 CCButton 承载
/// 布局: [静音 pika 图标] [标题] ......... [尾随(chevron / PRO / 红点 / 文字)]
public struct CCSettingRow: View {

    /// 行尾随元素
    public enum Trailing {
        case chevron          // 右箭头 (默认)
        case badge            // 红点提醒
        case pro              // PRO 粉标签
        case text(String)     // 灰色说明文字 + 箭头
        case value(String)    // 灰色说明文字，无箭头
        case none             // 无
    }

    let icon: String
    let title: String
    var tint: Color
    var titleColor: Color
    var trailing: Trailing

    /// 图标左对齐锚点 = 水平内边距 16 + 图标 20 + 间距 14 = 50 (供分隔线内缩对齐)
    public static let separatorInset: CGFloat = 50

    public init(
        icon: String,
        title: String,
        tint: Color = .cc.mutedForeground,
        titleColor: Color = .cc.foreground,
        trailing: Trailing = .chevron
    ) {
        self.icon = icon
        self.title = title
        self.tint = tint
        self.titleColor = titleColor
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: 14) {
            PikaIcon(icon, size: 20, color: tint)

            Text(title)
                .font(.cc.body)
                .foregroundStyle(titleColor)
                .lineLimit(1)

            Spacer(minLength: 8)

            trailingView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
        // 注意：本行永远被外层 Button 包裹，禁止在此加任何手势——
        // simultaneousGesture 会与外层 Button 抢 tap，导致点击时灵时不灵
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .chevron:
            PikaIcon("chevron-right", size: 18, color: .cc.mutedForeground)
        case .badge:
            Circle()
                .fill(Color.cc.destructive)
                .frame(width: 8, height: 8)
        case .pro:
            CCProTag()
        case .text(let value):
            HStack(spacing: 6) {
                Text(value)
                    .font(.cc.body)
                    .foregroundStyle(Color.cc.mutedForeground)
                    .lineLimit(1)
                PikaIcon("chevron-right", size: 18, color: .cc.mutedForeground)
            }
        case .value(let value):
            Text(value)
                .font(.cc.body)
                .foregroundStyle(Color.cc.mutedForeground)
                .lineLimit(1)
        case .none:
            EmptyView()
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCQuickAction (四宫格快捷动作 tile：图标在上，短标签在下)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 快捷动作 tile —— 纯展示，点击交互由外层 CCButton 承载
public struct CCQuickAction: View {
    let icon: String
    let title: String

    public init(icon: String, title: String) {
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        VStack(spacing: 8) {
            PikaIcon(icon, size: 22, color: .cc.foreground)
                .frame(height: 24)
            Text(title)
                .font(.cc.footnote)
                .foregroundStyle(Color.cc.mutedForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        // 同 CCSettingRow：外层 Button 承载点击，此处禁止加手势
    }
}

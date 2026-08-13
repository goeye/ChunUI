/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCLayout.swift                                   ║
 * ║                         布局结构组件库                                      ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: CCDesignSystem 主题、SwiftUI
 * [OUTPUT]: SubViewHeader, PageHeader, CCNavibarWithRightBtn
 * [POS]: DesignSystem/Compents 布局组件，被页面容器消费
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 子页面标题头
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 子页面统一标题头组件
    ///
    /// 用于设置页面（外观、语言、通知、账号安全等）的统一标题样式
    struct SubViewHeader: View {
        let icon: String
        let title: String
        let subtitle: String?

        public init(icon: String, title: String, subtitle: String? = nil) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    CCDesigin.ICON(imageName: icon, size: 20, color: .cc.foreground)
                    Text(title)
                        .ccText(font: .cc.title2Bold, color: .cc.foreground)
                }

                if let subtitle {
                    Text(subtitle)
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 页面标题头
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct PageHeader: View {
        let title: String

        public init(title: String) {
            self.title = title
        }

        public var body: some View {
            naviHeader
        }

        var naviHeader: some View {
            VStack(alignment: .center, spacing: 12) {
                Text(title)
                    .ccText(font: .cc.bodyBold, color: .cc.foreground)
                thinLine
            }
            .padding(.vertical, 24)
            .equatable(by: true)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 带右侧按钮的导航栏
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCNavibarWithRightBtn: View {
        let btnText: String
        let btnIcon: String?
        let btnAction: () async -> Void

        public init(btnText: String, btnIcon: String? = nil, btnAction: @escaping () async -> Void = {}) {
            self.btnText = btnText
            self.btnIcon = btnIcon
            self.btnAction = btnAction
        }

        public var body: some View {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)
                HStack(alignment: .center, spacing: 12, content: {
                    Spacer()
                    CCDesigin.Button(btnText, icon: btnIcon, size: .small, variant: .secondary) {
                        await btnAction()
                    }
                })
                .padding(.horizontal, 16)
                thinLine
                    .padding(.top, 12)
            }
        }
    }
}

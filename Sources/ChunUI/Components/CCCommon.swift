/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCCommon.swift                                   ║
 * ║                         通用基础组件库                                      ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: CCDesignSystem 主题、SwiftUI
 * [OUTPUT]: ICON（imageName → PikaIcons `pika/` 命名空间）、CCEmptyView
 * [POS]: DesignSystem/Compents 通用组件，被所有视图消费；禁止再引用已删除的 Assets.xcassets/ICON
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 图标组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct ICON: View {
        private let systemName: String?
        private let imageName: String?
        private let size: CGFloat
        private let color: Color

        public init(systemName: String, size: CGFloat = 24, color: Color = .cc.foreground) {
            self.systemName = systemName
            self.imageName = nil
            self.size = size
            self.color = color
        }

        public init(imageName: String, size: CGFloat = 24, color: Color = .cc.foreground) {
            self.imageName = imageName
            self.systemName = nil
            self.size = size
            self.color = color
        }

        public var body: some View {
            Group {
                if let systemName = systemName {
                    Image(systemName: systemName)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(color)
                } else if let imageName = imageName {
                    // 统一走 PikaIcons 命名空间，禁止依赖已废弃的 Assets.xcassets/ICON 裸名副本
                    Image(imageName.hasPrefix("pika/") ? imageName : "pika/\(imageName)")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(color)
                }
            }
            .frame(width: size, height: size)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 空状态组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCEmptyView: View {
        let image: String
        let title: String
        let subline: String

        public var body: some View {
            VStack(alignment: .center, spacing: 12) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240)
                Group {
                    Text(title)
                        .ccText(font: .cc.subheadlineBold, color: .cc.foreground)
                    Text(subline)
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                }
                .offset(x: 0, y: -24)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

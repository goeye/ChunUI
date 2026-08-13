//
//  GridBackground.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 DesignSystem/Theme 的 Color.cc 语义色
 * [OUTPUT]: 对外提供 GridBackground 组件（细线网格背景）
 * [POS]: DesignSystem/Compents 的背景组件，被 AdvisorChatView / AdvisorSidebarView 消费
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

/// 统一的细线网格背景（移植自 chat0-iOS GridBackground）
public struct GridBackground: View {
    let gridSize: CGFloat
    let lineColor: Color
    let lineWidth: CGFloat

    public init(
        gridSize: CGFloat = 20,
        lineColor: Color = Color.cc.border.opacity(0.35),
        lineWidth: CGFloat = 0.5
    ) {
        self.gridSize = gridSize
        self.lineColor = lineColor
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: - 基础背景色
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            Color.cc.background

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: - 细线网格
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    for x in stride(from: 0, through: width, by: gridSize) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }

                    for y in stride(from: 0, through: height, by: gridSize) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(lineColor, lineWidth: lineWidth)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GridBackground()
}

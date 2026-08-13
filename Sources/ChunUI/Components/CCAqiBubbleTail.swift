//
//  CCAqiBubbleTail.swift
//  Chat0IM
//

/**
 * [INPUT]: 仅依赖 SwiftUI Shape/Path 几何能力
 * [OUTPUT]: 对外提供 AqiBubbleTail，iMessage 式右下指向头像的气泡尖尾形状
 * [POS]: DesignSystem/Compents 的纯视觉几何原子，被 tabbar 阿奇 toast 与 Learn 分析页头像发言共用，不承载任何消息或定位状态
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

public struct AqiBubbleTail: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX * 0.2, y: rect.maxY * 0.95)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX * 0.55, y: 0),
            control: CGPoint(x: rect.maxX * 0.68, y: rect.maxY * 0.5)
        )
        path.closeSubpath()
        return path
    }
}

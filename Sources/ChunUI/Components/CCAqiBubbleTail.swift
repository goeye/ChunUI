//
//  CCAqiBubbleTail.swift
//  Chat0IM
//

/**
 * [INPUT]: 仅依赖 SwiftUI Shape/Path 几何能力
 * [OUTPUT]: 对外提供 AqiBubbleTail（iMessage 式右下指向头像的气泡尖尾）与 CCSpeechBubbleShape（Laper tooltip 法：气泡与底部中央尖尾一条闭合路径，fill/stroke 连续无接缝）
 * [POS]: Components 的纯视觉几何原子，被 toast 气泡 / Learn 分析页 / 宿主 Onboarding Hi 气泡共用，不承载任何消息或定位状态
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCSpeechBubbleShape（Laper tooltip 同构：气泡与尖尾一条闭合路径）
// 尾巴两肋凹弯（quad 控制点拉向中轴）+ 圆尖，基座直接长在底边上——
// 填充是一体的，描边沿尾巴连续绕行，不存在「三角形盖住边线」的补丁层
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCSpeechBubbleShape: Shape {
    public static let tailHeight: CGFloat = 10

    var cornerRadius: CGFloat = 22
    var tailWidth: CGFloat = 30
    var tailTipRadius: CGFloat = 2.5

    public init(cornerRadius: CGFloat = 22, tailWidth: CGFloat = 30, tailTipRadius: CGFloat = 2.5) {
        self.cornerRadius = cornerRadius
        self.tailWidth = tailWidth
        self.tailTipRadius = tailTipRadius
    }

    public func path(in rect: CGRect) -> Path {
        let tailH = Self.tailHeight
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailH)
        let r = min(cornerRadius, min(body.width, body.height) / 2)
        let midX = rect.midX
        let baseY = body.maxY
        let tipY = rect.maxY
        var p = Path()
        p.move(to: CGPoint(x: body.minX + r, y: body.minY))
        p.addLine(to: CGPoint(x: body.maxX - r, y: body.minY))
        p.addArc(center: CGPoint(x: body.maxX - r, y: body.minY + r), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: body.maxX, y: baseY - r))
        p.addArc(center: CGPoint(x: body.maxX - r, y: baseY - r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // 底边右段 → 尾巴右肋（凹弯下探到圆尖右肩）
        p.addLine(to: CGPoint(x: midX + tailWidth / 2, y: baseY))
        p.addQuadCurve(
            to: CGPoint(x: midX + tailTipRadius, y: tipY - tailTipRadius),
            control: CGPoint(x: midX + tailWidth * 0.2, y: baseY + tailH * 0.45)
        )
        // 圆尖
        p.addQuadCurve(
            to: CGPoint(x: midX - tailTipRadius, y: tipY - tailTipRadius),
            control: CGPoint(x: midX, y: tipY)
        )
        // 尾巴左肋 → 底边左段
        p.addQuadCurve(
            to: CGPoint(x: midX - tailWidth / 2, y: baseY),
            control: CGPoint(x: midX - tailWidth * 0.2, y: baseY + tailH * 0.45)
        )
        p.addLine(to: CGPoint(x: body.minX + r, y: baseY))
        p.addArc(center: CGPoint(x: body.minX + r, y: baseY - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: body.minX, y: body.minY + r))
        p.addArc(center: CGPoint(x: body.minX + r, y: body.minY + r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

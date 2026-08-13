//
//  CCSkeleton.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Color.cc 设计令牌（accent 骨架底 / foreground 流光取色）、TimelineView 帧时钟
 * [OUTPUT]: 对外提供 CCBone（骨架条原语：条/圆/自适应行）、CCBoneText（多行段落骨架，末行 2/3 宽）与 CCSkeleton（编排容器：整体压暗 0.55 + Laper 流光扫过）
 * [POS]: DesignSystem/Compents 的骨架屏唯一系统（Laper Skeleton 1:1 移植：100° 流光、前景 9% 峰值、12%→88% 柔边、2.6s 时钟取模）——替代一切 spinner；流光禁 repeatForever，与 shimmer/极光同构
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCBone（骨架条原语：底色 accent，条/圆两形）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCBone: View {
    var width: CGFloat? = nil       // nil 即吃满可用宽
    var height: CGFloat = 12
    var radius: CGFloat = 4
    var circle = false

    public init(width: CGFloat? = nil, height: CGFloat = 12, radius: CGFloat = 4, circle: Bool = false) {
        self.width = width
        self.height = height
        self.radius = radius
        self.circle = circle
    }

    public var body: some View {
        if circle {
            Circle()
                .fill(Color.cc.accent)
                .frame(width: height, height: height)
        } else if let width {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.cc.accent)
                .frame(width: width, height: height)
        } else {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.cc.accent)
                .frame(height: height)
                .frame(maxWidth: .infinity)
        }
    }
}

/// 多行段落骨架：末行 2/3 宽（Laper SkeletonText 同构）
public struct CCBoneText: View {
    var lines = 3
    var lineHeight: CGFloat = 12
    var spacing: CGFloat = 8

    public init(lines: Int = 3, lineHeight: CGFloat = 12, spacing: CGFloat = 8) {
        self.lines = lines
        self.lineHeight = lineHeight
        self.spacing = spacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0 ..< lines, id: \.self) { index in
                if index == lines - 1 {
                    GeometryReader { geo in
                        CCBone(width: geo.size.width * 2 / 3, height: lineHeight)
                    }
                    .frame(height: lineHeight)
                } else {
                    CCBone(height: lineHeight)
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCSkeleton（编排容器：调用方只传骨架样式，流光与淡化在此统一）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCSkeleton<Bones: View>: View {
    @ViewBuilder var bones: () -> Bones

    public init(@ViewBuilder bones: @escaping () -> Bones) {
        self.bones = bones
    }

    public var body: some View {
        bones()
            .modifier(CCSkeletonSweep())
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .transition(.opacity)
    }
}

/// Laper 流光纲领：100° 渐变、前景色 9% 峰值、12%→88% 柔边、2.6s 时钟取模、整体压暗 0.55
private struct CCSkeletonSweep: ViewModifier {
    private let period: TimeInterval = 2.6

    func body(content: Content) -> some View {
        content
            .opacity(0.55)
            .overlay {
                GeometryReader { geo in
                    TimelineView(.animation) { timeline in
                        let progress = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: period) / period
                        let phase = CGFloat(progress) * 2 - 1
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.12),
                                .init(color: Color.cc.foreground.opacity(0.09), location: 0.5),
                                .init(color: .clear, location: 0.88),
                            ],
                            startPoint: UnitPoint(x: 0, y: 0.38),
                            endPoint: UnitPoint(x: 1, y: 0.62)
                        )
                        .frame(width: geo.size.width)
                        .offset(x: phase * geo.size.width)
                    }
                    .transaction { $0.animation = nil }
                }
                .mask(content)
            }
    }
}

#Preview {
    VStack(spacing: 24) {
        CCSkeleton {
            HStack(spacing: 12) {
                CCBone(height: 34, circle: true)
                VStack(alignment: .leading, spacing: 8) {
                    CCBone(width: 90, height: 13)
                    CCBoneText(lines: 2)
                }
            }
        }
        CCSkeleton {
            CCBone(height: 180, radius: 20)
        }
    }
    .padding(24)
    .background(Color.cc.background)
}

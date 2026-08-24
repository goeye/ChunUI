//
//  CCSkeleton.swift
//  ChunUI
//

/**
 * [INPUT]: 依赖 Color.cc 设计令牌（accent 骨架底 / foreground 扫光取色）、TimelineView 帧时钟、Reduce Motion
 * [OUTPUT]: 对外提供 CCBone（骨架条原语：条/圆/自适应行，自带独立扫光）、CCBoneText（多行段落骨架：行宽各自随机、末行更短）与 CCSkeleton（编排容器：语义包裹 + 透明过渡）
 * [POS]: Components 的骨架屏唯一系统（Cloudflare Kumo SkeletonLine 形制，Laper Skeleton 同构：每条随机时长 1.3–1.7s + 随机负延迟相位、前景 8% 高光 ease-in-out 左→右往复；整片骨架不同步闪——同步闪是机械感，错开才像纸上的呼吸）——替代一切 spinner
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 扫光节奏（Kumo 随机区间：每实例挂载抽一次，渲染间稳定）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private enum CCBoneRhythmRange {
    static let duration: ClosedRange<Double> = 1.3 ... 1.7
}

/// 一条骨架的独立扫光节奏：时长 + 相位（负延迟等价——挂载即处于扫光中途，无等待期的静止高光）
private struct CCBoneRhythm {
    let duration: Double
    let phase: Double

    init() {
        duration = Double.random(in: CCBoneRhythmRange.duration)
        phase = Double.random(in: 0 ..< 1)
    }
}

/// CSS ease-in-out（cubic-bezier(0.42,0,0.58,1)）的平滑近似：扫光往中段快、两端缓
private func easeInOut(_ t: Double) -> Double {
    t * t * (3 - 2 * t)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 独立扫光（每条线自己呼吸；前景 8% 高光，Reduce Motion 静止）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCBoneShimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let rhythm = CCBoneRhythm()

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                            let t = timeline.date.timeIntervalSinceReferenceDate
                            let raw = (t / rhythm.duration + rhythm.phase)
                                .truncatingRemainder(dividingBy: 1)
                            let x = CGFloat(easeInOut(raw)) * 2 - 1
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: Color.cc.foreground.opacity(0.08), location: 0.5),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .frame(width: geo.size.width)
                            .offset(x: x * geo.size.width)
                        }
                        .transaction { $0.animation = nil }
                    }
                    .mask(content)
                }
            }
    }
}

extension View {
    /// 骨架条独立扫光（自定义骨架形状复用同一节奏纲领）
    func ccBoneShimmer() -> some View {
        modifier(CCBoneShimmer())
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCBone（骨架条原语：底色 accent，条/圆两形，自带扫光）
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
        bone.ccBoneShimmer()
    }

    @ViewBuilder
    private var bone: some View {
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

/// 多行段落骨架（Kumo SkeletonText 契约）：每行宽度各自随机（70–100%），末行更短（35–65%）
public struct CCBoneText: View {
    var lines = 3
    var lineHeight: CGFloat = 12
    var spacing: CGFloat = 8
    /// 每实例挂载抽一次的行宽比，渲染间稳定
    private let widthRatios: [CGFloat]

    public init(lines: Int = 3, lineHeight: CGFloat = 12, spacing: CGFloat = 8) {
        self.lines = lines
        self.lineHeight = lineHeight
        self.spacing = spacing
        self.widthRatios = (0 ..< max(1, lines)).map { index in
            index == lines - 1
                ? CGFloat.random(in: 0.35 ... 0.65)
                : CGFloat.random(in: 0.70 ... 1.0)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0 ..< lines, id: \.self) { index in
                GeometryReader { geo in
                    CCBone(width: geo.size.width * widthRatios[index], height: lineHeight)
                }
                .frame(height: lineHeight)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCSkeleton（编排容器：语义包裹；扫光在每条骨架内各自呼吸）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCSkeleton<Bones: View>: View {
    @ViewBuilder var bones: () -> Bones

    public init(@ViewBuilder bones: @escaping () -> Bones) {
        self.bones = bones
    }

    public var body: some View {
        bones()
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .transition(.opacity)
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
            CCBoneText(lines: 4)
        }
    }
    .padding(24)
    .background(Color.cc.background)
}

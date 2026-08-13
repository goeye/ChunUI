//
//  GeneratingCover.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Color.cc 语义色（muted 中性底 / mutedForeground 点阵色）
 * [OUTPUT]: 对外提供 CCGeneratingCover 生成中质感占位层（中性底 + 三团静态实体色氤氲 + 7pt 呼吸点阵 + 点阵遮罩白流光，1:1 移植 Laper GeneratingOverlay）
 * [POS]: DesignSystem/Effects 的占位质感层，被 DatingView 大卡/瀑布流卡在无形象照时铺底；流光周期 = 呼吸周期 × 2 且窗口居中，保证白光只在点阵膨胀顶点扫过
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCGeneratingCover（四层：中性底 → 氤氲 → 呼吸点阵 → 流光）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 「AI 生成中」占位质感：底绝不用实体色（浓底喧宾夺主），实体色只以 10-14% 混入氤氲
public struct CCGeneratingCover: View {
    /// 实体色（人物色），只染氤氲层
    let color: Color

    public init(color: Color = CCColors.current.primary) {
        self.color = color
    }

    // 呼吸周期 2.8s 往返；流光必须恒为呼吸 × 2，窗口居中在 50% 处对表
    private let breatheDuration: Double = 2.8

    @State private var breathing = false

    public var body: some View {
        ZStack {
            // ━━━ 第 0 层 · 中性底 ━━━
            Color.cc.muted

            // ━━━ 第 1 层 · 静态实体色氤氲（呼吸感全由上层点阵明暗带来）━━━
            mistLayer

            // ━━━ 第 2 层 · 呼吸点阵（scale 只向上不向下，回程即「收缩」）━━━
            dotsCanvas(Color.cc.mutedForeground.opacity(0.7))
                .mask(centerFade)
                .scaleEffect(breathing ? 1.18 : 1.0)
                .opacity(breathing ? 0.9 : 0.5)

            // ━━━ 第 3 层 · 流光（点阵自己被依次点亮，同步呼吸 scale 但不动 opacity）━━━
            sweepLayer
                .scaleEffect(breathing ? 1.18 : 1.0)
        }
        .clipped()
        .allowsHitTesting(false)
        .onAppear {
            guard !breathing else { return }
            withAnimation(.easeInOut(duration: breatheDuration).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 氤氲（三团径向椭圆，实体色 14%/10%/12%，圆心与淡出半径抄 Laper）
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var mistLayer: some View {
        ZStack {
            mistBlob(center: UnitPoint(x: 0.18, y: 0.32), strength: 0.14, fade: 0.46)
            mistBlob(center: UnitPoint(x: 0.66, y: 0.22), strength: 0.10, fade: 0.50)
            mistBlob(center: UnitPoint(x: 0.80, y: 0.76), strength: 0.12, fade: 0.48)
        }
    }

    private func mistBlob(center: UnitPoint, strength: Double, fade: CGFloat) -> some View {
        EllipticalGradient(
            stops: [
                .init(color: color.opacity(strength), location: 0),
                .init(color: color.opacity(strength), location: 0.26),
                .init(color: color.opacity(0), location: 1),
            ],
            center: center,
            startRadiusFraction: 0,
            endRadiusFraction: fade
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 点阵（7pt 网格 × 2pt 圆点，Canvas 静态绘制一次，动画全走合成器）
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func dotsCanvas(_ dotColor: Color) -> some View {
        Canvas { context, size in
            let step: CGFloat = 7
            var y: CGFloat = step / 2
            while y < size.height {
                var x: CGFloat = step / 2
                while x < size.width {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                        with: .color(dotColor)
                    )
                    x += step
                }
                y += step
            }
        }
    }

    /// 中心实、四角淡的椭圆遮罩：半径 58% 视口，实心到 8%（映射为 0.14）后淡出
    private var centerFade: some View {
        EllipticalGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.14),
                .init(color: .black.opacity(0), location: 1),
            ],
            center: .center,
            startRadiusFraction: 0,
            endRadiusFraction: 0.58
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 流光（白光带被点阵 ∩ 椭圆遮罩裁形，5.6s 一轮，36%-64% 窗口扫过）
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var sweepLayer: some View {
        GeometryReader { geo in
            sweepBand
                .keyframeAnimator(initialValue: CGFloat(-1.1), repeating: true) { view, progress in
                    view.offset(x: progress * geo.size.width)
                } keyframes: { _ in
                    KeyframeTrack {
                        // 0-36% 停在框外 → 36-50% 扫到中心 → 50-64% 扫出 → 64-100% 停在框外
                        LinearKeyframe(CGFloat(-1.1), duration: breatheDuration * 2 * 0.36)
                        LinearKeyframe(CGFloat(0), duration: breatheDuration * 2 * 0.14)
                        LinearKeyframe(CGFloat(1.1), duration: breatheDuration * 2 * 0.14)
                        LinearKeyframe(CGFloat(1.1), duration: breatheDuration * 2 * 0.36)
                    }
                }
        }
        .mask {
            dotsCanvas(.black).mask(centerFade)
        }
    }

    /// 100° 斜白光带：透明 32% → 白 40% → 纯白 50% → 白 40% → 透明 68%
    private var sweepBand: some View {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0), location: 0.32),
                .init(color: .white.opacity(0.4), location: 0.44),
                .init(color: .white, location: 0.50),
                .init(color: .white.opacity(0.4), location: 0.56),
                .init(color: .white.opacity(0), location: 0.68),
            ],
            startPoint: UnitPoint(x: 0, y: 0.41),
            endPoint: UnitPoint(x: 1, y: 0.59)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CCGeneratingCover(color: Color(red: 0.32, green: 0.42, blue: 0.29))
            .frame(width: 300, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

        CCGeneratingCover(color: .pink)
            .frame(width: 160, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .padding(24)
    .background(Color.cc.background)
}

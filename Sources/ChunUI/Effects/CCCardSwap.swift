//
//  CCCardSwap.swift
//  ChunUI
//

/**
 * [INPUT]: 依赖 SwiftUI 弹簧动画 + projectionEffect 斜切、Reduce Motion；形制移植 React Bits CardSwap（3D 牌堆：前卡坠落 → 群卡上位 → 前卡归尾，循环翻页）
 * [OUTPUT]: 对外提供 CCCardSwap——卡片轮换堆，双形态：diagonal 斜置 3D（槽位 x/y 阶梯 + z 纵深缩放 + 斜切）/ centered 居中同心叠（后卡缩阶微探头，零透视零横移，不撑版面）；任意张数只渲染前 visibleDepth 深度保性能
 * [POS]: Effects 的卡堆展示原语，宿主 Onboarding toolsShow 等消费；Reduce Motion 静止牌堆
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCCardSwap（每拍：前卡坠出 → 其余各进一槽 → 前卡从纵深归尾）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 堆叠形态：diagonal = React Bits 原版斜置 3D；centered = 居中同心叠（无斜切无横移）
public enum CCCardSwapStyle {
    case diagonal
    case centered
}

public struct CCCardSwap<Content: View>: View {
    var count: Int
    var style: CCCardSwapStyle
    var cardSize: CGSize
    var cardDistance: CGFloat
    var verticalDistance: CGFloat
    var delay: Double
    var skewDegrees: Double
    var visibleDepth: Int
    @ViewBuilder var content: (Int) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 卡 → 槽位（0 = 最前）
    @State private var slots: [Int] = []
    /// 坠落中的卡与其相位（坠出为正，归位清零）
    @State private var droppingCard: Int?
    @State private var dropOffset: CGFloat = 0
    @State private var frontReturning = false

    public init(
        count: Int,
        style: CCCardSwapStyle = .diagonal,
        cardSize: CGSize = CGSize(width: 260, height: 150),
        cardDistance: CGFloat = 34,
        verticalDistance: CGFloat = 40,
        delay: Double = 1.0,
        skewDegrees: Double = 6,
        visibleDepth: Int = 5,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.count = max(1, count)
        self.style = style
        self.cardSize = cardSize
        self.cardDistance = cardDistance
        self.verticalDistance = verticalDistance
        self.delay = max(0.5, delay)
        self.skewDegrees = skewDegrees
        self.visibleDepth = max(2, visibleDepth)
        self.content = content
    }

    public var body: some View {
        ZStack {
            ForEach(0 ..< count, id: \.self) { index in
                card(index)
            }
        }
        // 斜切仅 diagonal 形态（React skewY 同构：所有卡同角，剪切一次上容器）
        .projectionEffect(
            ProjectionTransform(CGAffineTransform(
                a: 1,
                b: style == .diagonal ? CGFloat(tan(-skewDegrees * .pi / 180)) : 0,
                c: 0, d: 1, tx: 0, ty: 0
            ))
        )
        // centered 只按本尺寸 + 微探头占位，不撑版面
        .frame(
            width: style == .diagonal
                ? cardSize.width + CGFloat(visibleDepth) * cardDistance
                : cardSize.width,
            height: style == .diagonal
                ? cardSize.height + CGFloat(visibleDepth) * verticalDistance
                : cardSize.height + CGFloat(visibleDepth - 1) * verticalDistance
        )
        .task(id: count) { await runLoop() }
    }

    @ViewBuilder
    private func card(_ index: Int) -> some View {
        let slot = index < slots.count ? slots[index] : index
        // 超出可见深度的卡钉在最后可见槽（透明待命），28 张也只动前几张
        let effSlot = min(slot, visibleDepth - 1)
        let dropping = droppingCard == index
        let z = CGFloat(effSlot) * cardDistance * 1.5
        // diagonal：纵深缩放模拟 perspective；centered：同心缩阶（每层 -5%）
        let scale = style == .diagonal ? 900 / (900 + z) : 1 - CGFloat(effSlot) * 0.05
        content(index)
            .frame(width: cardSize.width, height: cardSize.height)
            .scaleEffect(scale)
            .offset(
                x: style == .diagonal ? CGFloat(effSlot) * cardDistance : 0,
                y: -CGFloat(effSlot) * verticalDistance + (dropping ? dropOffset : 0)
            )
            .opacity(slot < visibleDepth ? 1 : 0)
            .zIndex(dropping && !frontReturning ? Double(count + 1) : Double(count - slot))
            .allowsHitTesting(slot == 0)
    }

    // ━━━ 循环：坠落 0.35s → 0.12s 起群卡上位 → 0.42s 起前卡归尾 → 满拍进下一轮 ━━━

    @MainActor
    private func runLoop() async {
        slots = Array(0 ..< count)
        guard count >= 2, !reduceMotion else { return }
        let promote = Animation.spring(response: 0.5, dampingFraction: 0.74)
        // 动画相位共 ~0.8s；空档 = delay − 0.8，保证「delay 秒一页」的整拍节奏
        let idle = max(0.15, delay - 0.8)
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(idle * 1_000_000_000))
            guard !Task.isCancelled else { return }
            guard let front = slots.firstIndex(of: 0) else { continue }

            // 1) 前卡坠出
            droppingCard = front
            frontReturning = false
            withAnimation(.easeIn(duration: 0.32)) {
                dropOffset = cardSize.height * 2.2
            }

            // 2) 其余各进一槽（坠落中段起步）
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(promote) {
                for i in slots.indices where i != front {
                    slots[i] -= 1
                }
            }

            // 3) 前卡沉底归尾（zIndex 先落底，无动画）
            try? await Task.sleep(nanoseconds: 300_000_000)
            frontReturning = true
            withAnimation(promote) {
                slots[front] = count - 1
                dropOffset = 0
            }
            try? await Task.sleep(nanoseconds: 380_000_000)
            droppingCard = nil
        }
    }
}

#Preview("卡堆轮换") {
    CCCardSwap(count: 6, delay: 1.0) { index in
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.cc.foreground)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            }
            .overlay {
                Text("Card \(index + 1)")
                    .ccText(font: .cc.lgBold, color: .cc.background)
            }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.cc.background)
}

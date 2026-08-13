//
//  CCCardDeck.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 SwiftUI 与 UIKit 触觉反馈器（无业务依赖）
 * [OUTPUT]: 对外提供 CCCardDeck 泛型无限轮转卡组容器（Tinder 手感：顶卡任意方向甩出→归入底部，后排右侧露边随拖拽顶位）
 * [POS]: DesignSystem/Compents 的卡片翻滚唯一真相源——订阅页套餐卡与对象页大卡共用，禁止各页自写卡组手势
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCCardDeck（Tinder 式无限轮转卡组：甩出→归底，拖拽推着后排顶位）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCCardDeck<Item: Identifiable & Equatable, Card: View>: View {
    /// 轮转事实源：外部持有以便读取当前顶卡（deck.first）
    @Binding var deck: [Item]
    /// 后排每张卡在右侧露出的宽度
    var peek: CGFloat = 20
    /// 入场控制：false 时整组隐藏，翻转为 true 时按 index 错峰浮现
    var revealed: Bool = true
    /// 每次轮转完成后的回调（同步选中态等）
    var onRotate: (() -> Void)? = nil
    @ViewBuilder var card: (_ item: Item, _ index: Int, _ isTop: Bool) -> Card

    public init(
        deck: Binding<[Item]>,
        peek: CGFloat = 20,
        revealed: Bool = true,
        onRotate: (() -> Void)? = nil,
        @ViewBuilder card: @escaping (_ item: Item, _ index: Int, _ isTop: Bool) -> Card
    ) {
        self._deck = deck
        self.peek = peek
        self.revealed = revealed
        self.onRotate = onRotate
        self.card = card
    }

    @State private var dragOffset: CGSize = .zero
    @State private var isFlying = false

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(deck.enumerated()), id: \.element.id) { index, item in
                let isTop = index == 0
                // 拖拽进度推着后排卡向前顶位，松手回弹（Tinder 手感的灵魂）
                let progress = isFlying ? 1 : min(1, abs(dragOffset.width) / 180 + abs(dragOffset.height) / 180)
                let slot = CGFloat(index) - (index > 0 ? progress : 0)

                card(item, index, isTop)
                    // anchor .trailing：缩小不吃掉右缘，后排卡从右侧露出 peek 宽度
                    .scaleEffect(1 - slot * 0.05, anchor: .trailing)
                    .offset(x: slot * peek)
                    .offset(isTop ? dragOffset : .zero)
                    .rotationEffect(.degrees(isTop ? Double(dragOffset.width) / 18 : 0), anchor: .bottom)
                    .zIndex(Double(deck.count - index))
                    // 高优先级手势：外层常为 ScrollView，普通 gesture 的纵向拖拽会被滚动吞掉
                    .highPriorityGesture(isTop && deck.count > 1 ? topCardDrag : nil)
                    .opacity(revealed ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82), value: deck)
                    .animation(
                        .spring(response: 0.62, dampingFraction: 0.8).delay(Double(index) * 0.07),
                        value: revealed
                    )
            }
        }
    }

    private var topCardDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isFlying else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isFlying else { return }
                let translation = value.translation
                let magnitude = hypot(translation.width, translation.height)

                guard magnitude > 96 else {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                        dragOffset = .zero
                    }
                    return
                }

                // 沿甩出方向飞离屏幕
                isFlying = true
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                let scale = 780 / magnitude
                withAnimation(.easeOut(duration: 0.26)) {
                    dragOffset = CGSize(width: translation.width * scale, height: translation.height * scale)
                }

                // 飞离后轮转卡组：飞出的卡从屏幕外弹回归入最底部，后排整体顶位
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                    withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                        deck.append(deck.removeFirst())
                        dragOffset = .zero
                    }
                    isFlying = false
                    UISelectionFeedbackGenerator().selectionChanged()
                    onRotate?()
                }
            }
    }
}

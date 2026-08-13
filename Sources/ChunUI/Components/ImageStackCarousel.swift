//
//  ImageStackCarousel.swift
//  YUI
//
//  Created by Claude on 2025/12/23.
//

/**
 * [INPUT]: UIImage 数组、当前索引、新添加索引、点击回调
 * [OUTPUT]: 堆叠式图片轮播组件（AppleCard 风格）
 * [POS]: 公用组件 - 图片堆叠轮播
 *
 * [PROTOCOL]:
 * 1. 滑动切换图片（左右拖拽）
 * 2. 点击查看大图（触发 onTapToView 回调）
 * 3. 底层图片随机旋转（-8°~-3° 或 3°~8°）
 * 4. AppleCard 双层阴影 + 边框
 * 5. Instagram 风格飞入动画
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Image Stack Carousel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct ImageStackCarousel: View {
    let images: [UIImage]
    @Binding var currentIndex: Int
    let newlyAddedIndex: Int?
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    var onTapToView: ((Int) -> Void)? = nil

    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    private let swipeThreshold: CGFloat = 50

    // ━━━ 预计算的随机角度缓存 ━━━
    @State private var rotationAngles: [Int: Double] = [:]
    @State private var dragOffset: CGFloat = 0

    public var body: some View {
        ZStack {
            if hasMultipleImages {
                ForEach(stackIndices, id: \.self) { index in
                    let isTop = index == currentIndex

                    imageCard(at: index, isTop: isTop)
                        .rotationEffect(.degrees(isTop ? 0 : getRotation(for: index)))
                        .offset(x: offsetX(for: index) + (isTop ? dragOffset * 0.3 : 0), y: offsetY(for: index))
                        .zIndex(Double(zIndex(for: index)))
                        .opacity(isTop ? 1.0 : 0.7)
                        .scaleEffect(isTop ? 1.0 : 0.92)
                        .transition(.asymmetric(insertion: .dealCardIn, removal: .opacity))
                        .id("\(index)_\(newlyAddedIndex == index)")
                }
            } else if let firstImage = images.first {
                imageCard(uiImage: firstImage, isTop: true)
                    .transition(.dealCardIn)
            }

            if hasMultipleImages {
                imageCountBadge
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .onTapGesture { onTapToView?(currentIndex) }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentIndex)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: images.count)
    }

    // ━━━ 滑动手势 ━━━
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let horizontalAmount = value.translation.width
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = 0
                    if horizontalAmount < -swipeThreshold {
                        // 左滑 → 下一张
                        cycleImage(forward: true)
                    } else if horizontalAmount > swipeThreshold {
                        // 右滑 → 上一张
                        cycleImage(forward: false)
                    }
                }
            }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var hasMultipleImages: Bool {
        images.count > 1
    }

    private var stackIndices: [Int] {
        guard hasMultipleImages else { return [] }
        let count = images.count
        var indices: [Int] = []

        for offset in -1...1 {
            let index = (currentIndex + offset + count) % count
            if !indices.contains(index) {
                indices.append(index)
            }
        }
        return indices.sorted()
    }

    // ━━━ 随机角度：-8~-3 或 3~8 ━━━
    private func getRotation(for index: Int) -> Double {
        if let cached = rotationAngles[index] {
            return cached
        }
        let angle = generateRandomRotation()
        DispatchQueue.main.async {
            rotationAngles[index] = angle
        }
        return angle
    }

    private func generateRandomRotation() -> Double {
        // 随机选择负区间或正区间
        let isNegative = Bool.random()
        if isNegative {
            return Double.random(in: -8 ... -3)
        } else {
            return Double.random(in: 3 ... 8)
        }
    }

    private func offsetX(for index: Int) -> CGFloat {
        let diff = index - currentIndex
        return CGFloat(diff) * 4
    }

    private func offsetY(for index: Int) -> CGFloat {
        let diff = abs(index - currentIndex)
        return CGFloat(diff) * -3
    }

    private func zIndex(for index: Int) -> Int {
        images.count - abs(index - currentIndex)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Image Card (AppleCard 风格)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func imageCard(at index: Int, isTop: Bool) -> some View {
        imageCard(uiImage: images[index], isTop: isTop)
    }

    private func imageCard(uiImage: UIImage, isTop: Bool) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: cardWidth - 20, height: cardHeight - 20)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            // ━━━ AppleCard 双层阴影 ━━━
            .shadow(color: Color.cc.shadow.opacity(0.08), radius: 6, y: 3)
            .shadow(color: Color.cc.shadow.opacity(isTop ? 0.2 : 0.1), radius: 12, y: 6)
            // ━━━ 边框 ━━━
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.cc.foreground.opacity(0.15), lineWidth: 1)
            }
    }

    // ━━━ 数量标签 ━━━
    private var imageCountBadge: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(currentIndex + 1)/\(images.count)")
                    .ccNumber(size: 12, color: .cc.darkCardForeground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cc.overlay.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(12)
            }
            Spacer()
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // ━━━ 轮播切换 ━━━
    private func cycleImage(forward: Bool = true) {
        guard hasMultipleImages else { return }
        hapticImpact.prepare()
        hapticImpact.impactOccurred(intensity: 0.6)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if forward {
                currentIndex = (currentIndex + 1) % images.count
            } else {
                currentIndex = (currentIndex - 1 + images.count) % images.count
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Instagram 风格飞入动画
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 发牌式飞入动画 - 从下到上、从大到小
public struct DealCardInModifier: ViewModifier {
    let isActive: Bool

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.3 : 1.0)
            .offset(y: isActive ? 150 : 0)
            .opacity(isActive ? 0 : 1)
    }
}

extension AnyTransition {
    /// Instagram风格发牌飞入：从下方飞入、从大变小、淡入
    static var dealCardIn: AnyTransition {
        .modifier(
            active: DealCardInModifier(isActive: true),
            identity: DealCardInModifier(isActive: false)
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#Preview {
    ImageStackCarouselPreview()
}

private struct ImageStackCarouselPreview: View {
    @State private var currentIndex = 0
    private let images: [UIImage] = [
        UIImage(named: "fake_photo_1") ?? UIImage(),
        UIImage(named: "fake_photo_2") ?? UIImage(),
        UIImage(named: "fake_photo_3") ?? UIImage()
    ]

    var body: some View {
        VStack {
            ImageStackCarousel(
                images: images,
                currentIndex: $currentIndex,
                newlyAddedIndex: nil,
                cardWidth: 170,
                cardHeight: 220
            )
        }
        .padding()
        .background(Color.cc.muted)
    }
}

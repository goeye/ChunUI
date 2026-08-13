//
//  CCUploadToast.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Color.cc/Font.cc 设计令牌、PikaIcon
 * [OUTPUT]: 对外提供 UploadProgressCenter 单例（批量上传任务的进度事实源：N 张图 N 条横杠，字节级 fraction；beginIfNeeded 供 picker 抢先弹出后上传层不重置）与 CCUploadToast 顶部浮动进度胶囊
 * [POS]: DesignSystem/Compents 的上传进度呈现层，经 CCToast.swift 的 CCToastWindow 同窗合流展示；R2Uploader.uploadImagesWithProgress 驱动
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - UploadProgressCenter（每张图一条横杠的进度事实源）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class UploadProgressCenter: ObservableObject {
    public static let shared = UploadProgressCenter()

    public enum BarState: Equatable {
        case uploading
        case done
        case failed
    }

    public struct Bar: Identifiable, Equatable {
        public let id = UUID()
        public var fraction: Double = 0
        public var state: BarState = .uploading
    }

    @Published public private(set) var bars: [Bar] = []
    @Published public private(set) var visible = false

    private var hideTask: Task<Void, Never>?

    private init() {}

    /// 开始一批上传：N 张图即 N 条横杠
    public func begin(count: Int) {
        hideTask?.cancel()
        bars = (0 ..< max(1, count)).map { _ in Bar() }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            visible = true
        }
    }

    /// picker 已抢先 begin 时，上传层不得重置横杠（否则胶囊闪一下再重来）
    public func beginIfNeeded(count: Int) {
        if visible { return }
        begin(count: count)
    }

    public func update(index: Int, fraction: Double) {
        guard bars.indices.contains(index) else { return }
        bars[index].fraction = min(max(fraction, bars[index].fraction), 1)
    }

    public func complete(index: Int, success: Bool) {
        guard bars.indices.contains(index) else { return }
        bars[index].fraction = 1
        bars[index].state = success ? .done : .failed
    }

    /// 批次收尾：短暂停留展示终态后淡出
    public func endSession(after delay: Double = 0.7) {
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                visible = false
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !visible { bars = [] }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCUploadToast（顶部浮动胶囊：图标 + 并排横杠，每杠实时充能）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCUploadToast: View {
    @ObservedObject private var center = UploadProgressCenter.shared

    /// 杠宽随张数收缩：1 张 88pt，6 张也能排进一行
    private var barWidth: CGFloat {
        let count = CGFloat(max(center.bars.count, 1))
        return max(14, min(88, 200 / count))
    }

    public var body: some View {
        if center.visible {
            HStack(spacing: 10) {
                PikaIcon("photo-image-arrow-up", size: 15, color: .cc.foreground)

                HStack(spacing: 5) {
                    ForEach(center.bars) { bar in
                        Capsule()
                            .fill(Color.cc.muted)
                            .frame(width: barWidth, height: 4)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(bar.state == .failed ? Color.cc.destructive : Color.cc.primary)
                                    .frame(width: barWidth * bar.fraction)
                                    .animation(.linear(duration: 0.12), value: bar.fraction)
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Color.cc.card, in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.cc.border.opacity(0.8), lineWidth: CGFloat.cc.hairline)
            }
            .shadow(color: Color.cc.shadow.opacity(0.12), radius: 10, x: 0, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

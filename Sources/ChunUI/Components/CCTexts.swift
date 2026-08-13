/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCTexts.swift                                    ║
 * ║                         文本展示组件库                                      ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: CCDesignSystem 主题、SwiftUI、AppHelper (震动反馈)
 * [OUTPUT]: CCText, CCTyperText
 * [POS]: DesignSystem/Compents 文本组件，被业务视图消费
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 占位文本组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCText: View {
        let str: String?
        let length: Int

        public init(str: String?, length: Int = 12) {
            self.str = str
            self.length = length
        }

        public var body: some View {
            if let str {
                Text(str)
            } else {
                Text(String.randomChineseString(length: length))
                    .isPlaceholder()
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 打字机效果文本
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCTyperText: View {
        let text: String
        let cursor: String
        let madaEnable: Bool
        let duration: Double?
        let font: Font
        let color: Color

        // ━━━ 马达震动最小时间间隔（秒）━━━
        private let madaMinInterval: TimeInterval = 0.2

        @State private var currentIndex: Int = 0
        @State private var timer: Timer?
        @State private var lastMadaTime: Date = .distantPast

        public init(_ text: String,
             cursor: String = "●",
             duration: Double? = nil,
             madaEnable: Bool = true,
             font: Font = .cc.body,
             color: Color = .cc.foreground)
        {
            self.text = text
            self.cursor = cursor
            self.duration = duration
            self.madaEnable = madaEnable
            self.font = font
            self.color = color
        }

        // ━━━ 兼容旧调用方式 vtext: ━━━
        public init(vtext: String,
             cursor: String = "●",
             duration: Double? = nil,
             madaEnable: Bool = true,
             font: Font = .cc.body,
             color: Color = .cc.foreground)
        {
            self.text = vtext
            self.cursor = cursor
            self.duration = duration
            self.madaEnable = madaEnable
            self.font = font
            self.color = color
        }

        private var shouldShowCursor: Bool {
            currentIndex < text.count
        }

        private func scheduleTimer() {
            let interval: TimeInterval
            if let duration = duration {
                interval = duration / Double(text.count)
            } else {
                interval = Double.random(in: 0.05 ... 0.08)
            }

            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                if currentIndex < text.count {
                    DispatchQueue.main.async {
                        currentIndex += 1
                        if madaEnable {
                            // 检查是否已经超过最小时间间隔
                            let now = Date()
                            if now.timeIntervalSince(lastMadaTime) >= madaMinInterval {
                                AppHelper.shared.mada(.soft)
                                lastMadaTime = now
                            }
                        }
                        scheduleTimer()
                    }
                }
            }
        }

        public var body: some View {
            let showText = String(text.prefix(currentIndex)) + (shouldShowCursor ? cursor : "")
            Text(showText)
                .ccText(font: font, color: color)
                .contentTransition(.numericText())
                .animation(.smooth, value: currentIndex)
                .fixedSize(horizontal: false, vertical: true)
                .onAppear {
                    currentIndex = 0
                    scheduleTimer()
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
        }
    }
}

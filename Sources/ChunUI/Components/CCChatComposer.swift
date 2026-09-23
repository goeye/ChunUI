//
//  CCChatComposer.swift
//  ChunUI
//

/**
 * [INPUT]: 依赖 Color.cc / Font.cc 令牌、ccNeoChromeCircle 圆钮质感、PikaIcon、AppHelper 触感
 * [OUTPUT]: 对外提供 CCChatComposer——对话输入坞：1~6 行自长输入 + 右侧正圆发送钮；running 时发送钮换成停止钮
 * [POS]: Components 的通用对话输入原语（卡片底 + 发丝边 + 焦点环，与 CCNeoInput 同一副外观）；业务坞（附件、@ 人）在宿主里包它
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

public struct CCChatComposer: View {
    let placeholder: String
    @Binding var text: String
    var running: Bool
    var onSend: (String) -> Void
    var onStop: () -> Void

    @FocusState private var focused: Bool

    private let buttonSize: CGFloat = 34
    private let radius: CGFloat = 24

    public init(
        placeholder: String,
        text: Binding<String>,
        running: Bool = false,
        onSend: @escaping (String) -> Void,
        onStop: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self.running = running
        self.onSend = onSend
        self.onStop = onStop
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// 有字就能发（在跑也能插话）；没字且在跑时钮是停止
    private var showsStop: Bool { running && trimmed.isEmpty }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(Font.cc.body)
                .foregroundStyle(Color.cc.foreground)
                .tint(Color.cc.primary)
                .lineLimit(1...6)
                .focused($focused)
                .padding(.vertical, 9)
                .padding(.leading, 8)

            Button(action: tap) {
                PikaIcon(showsStop ? "stop-small" : "arrow-up", size: 18, color: .cc.primaryForeground)
                    .frame(width: buttonSize, height: buttonSize)
                    .ccNeoChromeCircle(.primary, diameter: buttonSize, disabled: !showsStop && trimmed.isEmpty)
                    .contentShape(Circle())
            }
            .buttonStyle(CCNeoPressStyle())
            .disabled(!showsStop && trimmed.isEmpty)
            .animation(.smooth(duration: 0.2), value: showsStop)
        }
        .padding(7)
        .background(Color.cc.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(
                    focused ? Color.cc.primary.opacity(0.7) : Color.cc.border.opacity(0.7),
                    lineWidth: focused ? 1.2 : CGFloat.cc.hairline
                )
        }
        .animation(.easeInOut(duration: 0.16), value: focused)
    }

    private func tap() {
        if showsStop {
            AppHelper.shared.mada(.medium)
            onStop()
            return
        }
        let message = trimmed
        guard !message.isEmpty else { return }
        AppHelper.shared.mada(.soft)
        text = ""
        onSend(message)
    }
}

#Preview {
    VStack {
        Spacer()
        CCChatComposer(placeholder: "Message", text: .constant(""), onSend: { _ in })
        CCChatComposer(placeholder: "Message", text: .constant(""), running: true, onSend: { _ in })
    }
    .padding()
    .background(Color.cc.background)
}

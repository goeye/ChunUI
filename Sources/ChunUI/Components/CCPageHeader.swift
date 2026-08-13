//
//  CCPageHeader.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Color.cc/Font.cc 设计令牌与 ccText
 * [OUTPUT]: 对外提供 CCPageHeader（title2Bold 标题 + footnote 灰阶副标题 + trailing 槽位的编辑气质页头）
 * [POS]: DesignSystem/Compents 的页头原子组件，取代各 tab 页的 hero 大标题；克制的字阶层次 = 顾问软件气质
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCPageHeader（标题 + 副标题 + trailing 槽）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCPageHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    /// 自定义副标题槽（如 CCKeycapTag），非空时优先于 subtitle 文本
    var subtitleView: AnyView? = nil
    @ViewBuilder var trailing: () -> Trailing

    public init(
        title: String,
        subtitle: String? = nil,
        subtitleView: AnyView? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleView = subtitleView
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .ccText(font: .cc.title2Bold, color: .cc.foreground)
                if let subtitleView {
                    subtitleView
                        .padding(.top, 3)
                } else if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                }
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

extension CCPageHeader where Trailing == EmptyView {
    public init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, subtitleView: nil) { EmptyView() }
    }

    public init(title: String, subtitleView: AnyView?) {
        self.init(title: title, subtitle: nil, subtitleView: subtitleView) { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 0) {
        CCPageHeader(title: "对象", subtitle: "3 位在册") {
            CCDesigin.GlassIconButton(icon: "grid-dashboard01") {}
        }
        CCPageHeader(title: "知识", subtitle: "约会前的行业功课")
        Spacer()
    }
    .background(Color.cc.background)
}

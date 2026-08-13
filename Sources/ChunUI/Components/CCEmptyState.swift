/**
 * [INPUT]: 依赖 Color.cc/Font.cc、Assets.xcassets/Illustration/empty-no-*（oxipng 无损）
 * [OUTPUT]: 对外提供 CCEmptyKind + CCEmptyState——一级页/个人主页模块统一缺省图组件（message + 可选 detail 两行）
 * [POS]: DesignSystem/Compents 的空态真相源；禁止业务页手写 Image+灰字拼凑
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 缺省图枚举（与 Illustration/empty-no-* 一一对应）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCEmptyKind: String {
    /// 对象列表
    case contact = "empty-no-contact"
    /// 往来 / 约会记录
    case interactions = "empty-no-interactions"
    /// 知识 / 话题
    case knowledge = "empty-no-knowledge"
    /// 备忘 tips
    case memos = "empty-no-memos"
    /// 自动化（Learn）
    case tools = "empty-no-tools"

    var imageName: String { rawValue }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCEmptyState
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCEmptyState: View {
    let kind: CCEmptyKind
    var message: String
    /// 第二行说明；空则只渲染 message
    var detail: String? = nil
    /// 插图边长；一级页默认 200，模块内嵌可更小
    var imageSize: CGFloat = 200
    /// 模块内嵌时去掉撑满 Spacer，只占内容高度
    var compact = false

    public init(kind: CCEmptyKind, message: String, detail: String? = nil, imageSize: CGFloat = 200, compact: Bool = false) {
        self.kind = kind
        self.message = message
        self.detail = detail
        self.imageSize = imageSize
        self.compact = compact
    }

    public var body: some View {
        Group {
            if compact {
                content
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack {
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .allowsHitTesting(false)
    }

    private var content: some View {
        VStack(spacing: 0) {
            Image(kind.imageName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .accessibilityHidden(true)

            // 插图自带透明 padding，文字上提贴紧视觉主体
            VStack(spacing: 4) {
                Text(message)
                    .font(.cc.footnote)
                    .foregroundStyle(Color.cc.mutedForeground)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.cc.footnote)
                        .foregroundStyle(Color.cc.mutedForeground)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, -28)
        }
    }
}

#Preview("缺省·对象") {
    CCEmptyState(
        kind: .contact,
        message: CCStrings.current.empty
    )
    .background(Color.cc.background)
}

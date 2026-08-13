/**
 * [INPUT]: 依赖 Color.cc/Font.cc、CCNeoPressStyle
 * [OUTPUT]: 对外提供 CCIllustrationTile——插图方块（上头图 + 下标题/箭头）
 * [POS]: DesignSystem 插图动作瓦片；Dating 快捷菜单 / Learn 微信·键盘双入口共用
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

/// 插图动作瓦片——与首页「+」四宫格同构：顶插图、底标题 + ↗
public struct CCIllustrationTile: View {
    let image: String
    let title: String
    /// 标题左侧 pikaicon 名（nil = 不显示）
    var titleIcon: String?
    var tileRadius: CGFloat = 18
    var illustrationHeight: CGFloat = 72
    var minHeight: CGFloat = 118
    /// 瓦片底色；自动化页用 `.card` 白卡，快捷菜单默认 page background
    var surface: Color = Color.cc.background
    var onTap: () -> Void

    public init(
        image: String,
        title: String,
        titleIcon: String? = nil,
        tileRadius: CGFloat = 18,
        illustrationHeight: CGFloat = 72,
        minHeight: CGFloat = 118,
        surface: Color = Color.cc.background,
        onTap: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        self.titleIcon = titleIcon
        self.tileRadius = tileRadius
        self.illustrationHeight = illustrationHeight
        self.minHeight = minHeight
        self.surface = surface
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            AppHelper.shared.mada(.soft)
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: illustrationHeight)
                    .clipped()
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: tileRadius - 4,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: tileRadius - 4,
                            style: .continuous
                        )
                    )
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                HStack(alignment: .center, spacing: 5) {
                    if let titleIcon {
                        PikaIcon(titleIcon, size: 16, color: .cc.foreground)
                    }
                    Text(title)
                        .font(.cc.bodyBold)
                        .foregroundStyle(Color.cc.foreground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 2)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.cc.mutedForeground)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .top)
            .background(surface, in: RoundedRectangle(cornerRadius: tileRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                    .strokeBorder(Color.cc.border.opacity(0.55), lineWidth: CGFloat.cc.hairline)
            }
            .contentShape(RoundedRectangle(cornerRadius: tileRadius, style: .continuous))
        }
        .buttonStyle(CCNeoPressStyle())
    }
}

/**
 * [INPUT]: MainViewModel.selectedTab/requestChatFocus、CCTabItem、PikaIcon、BrandLogo、AppHelper 触感、CCToastCenter.advisorAvatarAnchor
 * [OUTPUT]: 四常规项 + 最右顾问圆形阿奇头像按钮（点击切顾问页并自动聚焦输入坞，已在页时二次点击同样聚焦）；头像全局 frame 持续上报 CCToastCenter 供阿奇气泡 toast 锚定
 * [POS]: DesignSystem/Compents 主底栏；MainView offset +8pt 贴屏底
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

struct MainTabbar: View {
    @ObservedObject var vm: MainViewModel = .shared

    /// 常规项行高；顾问圆头像与此对齐
    private let capsuleHeight: CGFloat = 52
    private let advisorAvatarSize: CGFloat = 52

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 10) {
                ForEach(CCTabItem.regularTabs, id: \.self) { tab in
                    tabItemView(tab: tab, selected: vm.selectedTab == tab)
                }
                advisorCapsule
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
    }

    private func handleTabTap(_ tab: CCTabItem) {
        AppHelper.shared.mada(.light)
        CCTrack.onTap("tab:" + String(describing: tab))
        // 顾问球：切页即聚焦输入坞（已在顾问页时二次点击同样聚焦）
        if tab == .advisor {
            vm.requestChatFocus()
        }
        vm.switchTab(tab)
    }

    private func tabItemView(tab: CCTabItem, selected: Bool) -> some View {
        Button {
            handleTabTap(tab)
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    PikaIcon(tab.iconName, size: 24, color: .cc.mutedForeground)
                        .opacity(selected ? 0 : 1)
                    PikaIcon(tab.selectedIconName, size: 24, color: .cc.foreground)
                        .opacity(selected ? 1 : 0)
                        .scaleEffect(selected ? 1 : 0.7)
                        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: selected)
                }
                .frame(height: 24)
                Text(tab.title)
                    .ccText(
                        font: AppLocalization.isChineseUI ? .cc.tabbar : .cc.tabbarCompact,
                        color: selected ? .cc.foreground : .cc.mutedForeground
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .animation(.easeInOut(duration: 0.16), value: selected)
            .frame(width: 58, height: capsuleHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 顾问：圆形阿奇头像
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var advisorCapsule: some View {
        let selected = vm.selectedTab == .advisor
        return Button {
            handleTabTap(.advisor)
        } label: {
            Image("BrandLogo")
                .resizable()
                .scaledToFill()
                .frame(width: advisorAvatarSize, height: advisorAvatarSize)
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(
                        Color.white.opacity(selected ? 0.55 : 0.28),
                        lineWidth: 1
                    )
                )
                .shadow(color: .black.opacity(selected ? 0.12 : 0.06), radius: selected ? 8 : 4, x: 0, y: 2)
                .scaleEffect(selected ? 1.04 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 4)
        .accessibilityLabel(CCTabItem.advisor.title)
        // 头像全局 frame 上报：阿奇气泡 toast 的尖尾锚点事实源
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            CCToastCenter.shared.advisorAvatarAnchor = frame
        }
    }

}

#Preview {
    ZStack {
        Color.cc.background.ignoresSafeArea()
        VStack {
            Spacer()
            MainTabbar()
        }
    }
}

//
//  ProfileView.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 ProfileViewModel、UserManager、PurchaseManager、ConfigStore、CCSettingRow/ccGroupCard
 * [OUTPUT]: 对外提供 ProfileView 与 ProfileSettings* 子页根组件（纯布局）
 * [POS]: Features/Profile 设置主页 UI；ViewModel 在 ProfileViewModel.swift；已是 Pro 点订阅进 MySubView，未订阅进 VipBuyView；会员态不展示恢复购买；账号区无邮件行、无数据控制入口
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var userManager = UserManager.shared
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @ObservedObject private var configStore = ConfigStore.shared

    private var user: CCUser { userManager.user }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                profileHeader
                sections
                signOutButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 42)
        }
        .isCCMainScrollView()
        .background(Color.cc.background.ignoresSafeArea())
        .overlay(alignment: .topTrailing) { upgradeButton }
    }

    /// 右上角订阅直达（纯文字粉色胶囊；后端 isProUser 或本地 Premium.isActive 任一为 Pro 即不展示）
    @ViewBuilder
    private var upgradeButton: some View {
        if !purchaseManager.isProUser && !Premium.isActive {
            Button {
                AppHelper.shared.mada(.soft)
                MainViewModel.shared.presentFullScreen(view: VipBuyView())
            } label: {
                Text(verbatim: "PRO")
                    .font(.cc.smBold)
                    .foregroundStyle(Color.cc.primaryForeground)
                    .padding(.horizontal, 16)
                    .frame(height: 34)
                    .background(Color.cc.primary, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(CCNeoPressStyle())
            .padding(.trailing, 18)
            .padding(.top, 10)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Header
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var profileHeader: some View {
        VStack(spacing: 12) {
            CCUserAvatar(size: 104, cornerRadius: 52, navigatesToProfile: false)

            VStack(spacing: 2) {
                Text(displayName)
                    .ccText(font: .cc.title1Bold, color: .cc.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(username)
                    .ccText(font: .cc.title3, color: .cc.mutedForeground)
                    .lineLimit(1)
            }

            Button {
                AppHelper.shared.presentSheet(.form) {
                    ProfileEditView()
                }
            } label: {
                Text("profile.edit_profile".local())
                    .ccText(font: .cc.callout, color: .cc.foreground)
                    .padding(.horizontal, 22)
                    .frame(height: 38)
                    .overlay {
                        Capsule()
                            .stroke(Color.cc.border.opacity(0.9), lineWidth: 1)
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Sections
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var sections: some View {
        VStack(alignment: .leading, spacing: 22) {
            personaSection
            settingsSection(accountItems, title: "profile.section.account".local())
            settingsSection(appItems, title: "profile.section.app".local())
            settingsSection(aboutItems, title: nil)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 我的人设（banner 首行 + 人设资料 / 社交目标；AI 千人千面的用户侧入口）
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var personaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("profile.persona.section".local())
                .ccText(font: .cc.title3Bold, color: .cc.mutedForeground)
                .padding(.leading, 18)

            VStack(spacing: 0) {
                personaBanner
                hairline
                ForEach(Array(personaItems.enumerated()), id: \.element.id) { index, item in
                    settingRow(item)
                    if index < personaItems.count - 1 { hairline }
                }
            }
            .ccGroupCard(radius: 30)
        }
    }

    /// banner 行：人设插图铺底（主体在右、左侧留白天然承文案），点击直达人设资料
    private var personaBanner: some View {
        Button {
            AppHelper.shared.presentSheet(.form) { PersonaEditSheet() }
        } label: {
            ZStack(alignment: .leading) {
                Image("persona-banner")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 96)
                    .frame(maxWidth: .infinity)
                    .clipped()

                Text("profile.persona.banner".local())
                    .font(.cc.baseBold)
                    .foregroundStyle(Color.cc.foreground)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
                    .padding(.trailing, 150)
            }
            .frame(height: 96)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 30,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 30,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(CCListRowPressStyle())
    }

    private var personaItems: [ProfileViewModel.SettingItem] {
        [
            .init(title: "profile.persona.profile".local(), icon: "id-card") {
                AppHelper.shared.presentSheet(.form) { PersonaEditSheet() }
            },
            .init(title: "profile.persona.goal".local(), icon: "target-center") {
                AppHelper.shared.presentSheet(.compact(400)) { SocialGoalSheet() }
            },
        ]
    }

    private func settingsSection(_ items: [ProfileViewModel.SettingItem], title: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .ccText(font: .cc.title3Bold, color: .cc.mutedForeground)
                    .padding(.leading, 18)
            }

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    settingRow(item)
                    if index < items.count - 1 { hairline }
                }
            }
            .ccGroupCard(radius: 30)
        }
    }

    @ViewBuilder
    private func settingRow(_ item: ProfileViewModel.SettingItem) -> some View {
        switch item.kind {
        case .button:
            Button {
                item.action?()
            } label: {
                CCSettingRow(icon: item.icon, title: item.title, tint: .cc.foreground, trailing: item.trailing)
            }
            .buttonStyle(CCListRowPressStyle())
        case .toggle(let binding):
            HStack(spacing: 14) {
                PikaIcon(item.icon, size: 20, color: .cc.foreground)
                Text(item.title)
                    .font(.cc.body)
                    .foregroundStyle(Color.cc.foreground)
                Spacer(minLength: 8)
                Toggle("", isOn: binding)
                    .labelsHidden()
                    .tint(Color.cc.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.cc.border.opacity(0.62))
            .frame(height: .cc.hairline)
            .padding(.leading, CCSettingRow.separatorInset)
            .padding(.trailing, 18)
    }

    private var isMember: Bool { purchaseManager.isProUser || Premium.isActive }

    private var accountItems: [ProfileViewModel.SettingItem] {
        var items: [ProfileViewModel.SettingItem] = [
            .init(title: "profile.subscription".local(), icon: "credit-card", trailing: .value(subscriptionLabel)) {
                openSubscription()
            },
        ]
        if !isMember {
            items.append(
                .init(title: "store.restore_purchase".local(), icon: "credit-card-arrow-repeat", trailing: .none) {
                    Task { await PurchaseManager.shared.restorePurchases() }
                }
            )
        }
        items.append(
            .init(title: "profile.notifications".local(), icon: "notification-bell-on") {
                MainViewModel.shared.push(view: NotificationSettingsView())
            }
        )
        return items
    }

    private var appItems: [ProfileViewModel.SettingItem] {
        [
            .init(title: "profile.language".local(), icon: "translate", trailing: .text(configStore.currentLanguageDisplayName)) {
                MainViewModel.shared.push(view: LanguageSettingsView())
            },
            .init(title: "profile.appearance".local(), icon: "moon", trailing: .text(configStore.appearanceMode.displayName)) {
                MainViewModel.shared.push(view: AppearanceSettingsView())
            },
        ]
    }

    private var aboutItems: [ProfileViewModel.SettingItem] {
        [
            .init(title: "profile.rate_app".local(), icon: "thumb-reaction-like") {
                UIApplication.shared.open(AppConfig.AppStoreReviewURL)
            },
            .init(title: "profile.share_app".local(), icon: "share01") {
                let activity = UIActivityViewController(
                    activityItems: [AppConfig.AppStoreURL],
                    applicationActivities: nil
                )
                AppHelper.shared.topMostViewController()?.present(activity, animated: true)
            },
            .init(title: "profile.about".local(), icon: "information-circle") {
                MainViewModel.shared.pushPageSheet(view: AboutAppView())
            },
        ]
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Sign Out
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var signOutButton: some View {
        Button {
            UserManager.shared.logOut()
        } label: {
            Text("profile.sign_out".local())
                .ccText(font: .cc.body, color: .cc.destructive)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(CCListRowPressStyle())
        .ccGroupCard(radius: 28)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Derived
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var displayName: String {
        if !user.display_name.isEmpty { return user.display_name }
        if !user.username.isEmpty { return user.username }
        return "profile.default_name".local()
    }

    private var username: String {
        user.username.isEmpty ? "@" + "profile.default_username".local() : "@\(user.username)"
    }

    private var subscriptionLabel: String {
        purchaseManager.isProUser ? "profile.subscription_pro".local() : "profile.subscription_free".local()
    }

    private func openSubscription() {
        if isMember {
            MainViewModel.shared.pushPageSheet(view: MySubView())
        } else {
            MainViewModel.shared.presentFullScreen(view: VipBuyView())
        }
    }
}

#Preview {
    ProfileView()
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Profile 子设置页根组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ProfileSettingsPage<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                titleBar
                content()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 42)
        }
        .isCCMainScrollView()
        .background(Color.cc.background.ignoresSafeArea())
    }

    private var titleBar: some View {
        HStack(spacing: 12) {
            CCDesigin.GlassIconButton(icon: "arrow-left") {
                MainViewModel.shared.pop()
            }
            .accessibilityLabel("common.back".local())

            Text(title)
                .ccText(font: .cc.title3Bold, color: .cc.foreground)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(height: 42)
        .padding(.bottom, 8)
    }
}

struct ProfileSettingsGroup<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content

    init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .ccText(font: .cc.title3Bold, color: .cc.mutedForeground)
                    .padding(.leading, 18)
            }

            VStack(spacing: 0) {
                content()
            }
            .ccGroupCard(radius: 30)
        }
    }
}

struct ProfileSelectableRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 14) {
                PikaIcon(icon, size: 20, color: .cc.foreground)
                Text(title)
                    .font(.cc.body)
                    .foregroundStyle(Color.cc.foreground)
                Spacer(minLength: 8)
                if isSelected {
                    PikaIcon("check-tick.", size: 16, color: .cc.foreground)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(CCListRowPressStyle())
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            PikaIcon(icon, size: 20, color: .cc.foreground)
            Text(title)
                .font(.cc.body)
                .foregroundStyle(Color.cc.foreground)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(value)
                .font(.cc.footnote)
                .foregroundStyle(Color.cc.mutedForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    var tint: Color = .cc.foreground
    var trailingIcon: String? = "chevron-right"
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 14) {
                PikaIcon(icon, size: 20, color: tint)
                Text(title)
                    .font(.cc.body)
                    .foregroundStyle(tint)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let trailingIcon {
                    PikaIcon(trailingIcon, size: 16, color: .cc.mutedForeground.opacity(0.45))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(CCListRowPressStyle())
    }
}

struct ProfileGroupDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.cc.border.opacity(0.62))
            .frame(height: .cc.hairline)
            .padding(.leading, CCSettingRow.separatorInset)
            .padding(.trailing, 18)
    }
}

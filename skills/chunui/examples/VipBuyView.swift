//
//  VipBuyView.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 VipBuyViewModel、PurchaseManager 发布态、SubscriptionPlanKeycap、buy / buy-winback 全宽插图、store.paywall.* 文案
 * [OUTPUT]: 对外提供 VipBuyView（纯布局：hero + 融边插图 + 硬墙试用 CTA / 挽回图下「仅此一次」+ 单档 369 年 + 键帽 + 双行 CTA）；mode=.paywall 关钮走 onSkip、.winback 关钮与「暂不需要」踢出登录、hero 走 buy-winback
 * [POS]: Features/Store 订阅入口 UI；登录后硬墙 GateFlow.paywall / 挽回步直接复用本页
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

struct VipBuyView: View {
    @StateObject private var vm: VipBuyViewModel
    @ObservedObject private var purchase = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    let mode: VipBuyMode
    var onSkip: (() -> Void)?
    /// 硬墙/挽回购成 → GateFlow 放行；缺省走 VM enterHome
    var onPurchased: (() -> Void)?

    private var isPaywall: Bool { mode != .store }
    private var isWinback: Bool { mode == .winback }

    init(mode: VipBuyMode = .store, onSkip: (() -> Void)? = nil, onPurchased: (() -> Void)? = nil) {
        self.mode = mode
        self.onSkip = onSkip
        self.onPurchased = onPurchased
        _vm = StateObject(wrappedValue: VipBuyViewModel(mode: mode))
    }

    init(isPaywall: Bool, onSkip: (() -> Void)? = nil, onPurchased: (() -> Void)? = nil) {
        self.init(mode: isPaywall ? .paywall : .store, onSkip: onSkip, onPurchased: onPurchased)
    }

    var body: some View {
        ZStack {
            Color.cc.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    heading
                        .padding(.horizontal, 22)
                        .padding(.bottom, 12)
                        .zIndex(1)   // 文字永远压在插图之上

                    heroImage
                        .padding(.top, -22)
                        .padding(.bottom, isPaywall ? 12 : 20)
                        .zIndex(0)

                    if mode == .paywall {
                        trialContinueHint
                            .padding(.horizontal, 22)
                            .padding(.top, -22)
                            .padding(.bottom, 20)
                            .zIndex(1)
                    } else if isWinback {
                        winbackOfferHint
                            .padding(.horizontal, 22)
                            .padding(.top, -22)
                            .padding(.bottom, 20)
                            .zIndex(1)
                    }

                    plans
                        .padding(.horizontal, 22)
                        .padding(.bottom, 18)

                    purchaseButton
                        .padding(.horizontal, 22)
                        .padding(.bottom, isWinback ? 8 : 14)

                    if isWinback {
                        skipButton
                            .padding(.horizontal, 22)
                            .padding(.bottom, 14)
                    }

                    footerLinks
                        .padding(.horizontal, 22)
                        .padding(.bottom, 10)

                    underText
                        .padding(.horizontal, 22)
                }
                .padding(.top, 64)
                .padding(.bottom, 36)
            }
            .blur(radius: purchase.isPurchasing ? 12 : 0)

            // 关闭按钮固定不随滚动（只有内容滚）
            topBar
                .padding(.horizontal, 22)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 10)
        }
        .animation(.smooth(duration: 0.28), value: purchase.isPurchasing)
        .onAppear { vm.onAppear() }
        .onChange(of: vm.requestDismiss) { _, dismissNow in
            if dismissNow && !isPaywall { dismiss() }
        }
        .onChange(of: purchase.packages.map(\.identifier) + purchase.winbackPackages.map(\.identifier)) { _, _ in
            vm.syncSelectedPackage()
        }
        .onChange(of: purchase.isProUser) { _, pro in
            if isPaywall && pro { onPurchased?() }
        }
        .onChange(of: purchase.showBuySuccessHand) { _, done in
            if !done && isPaywall && purchase.isProUser && onPurchased == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    vm.enterHomeAfterPaywallPurchase()
                }
            }
        }
        .onChange(of: purchase.purchaseError) { _, error in
            guard let error, !error.isEmpty else { return }
            AppHelper.shared.showBottomAlert(
                title: "store.purchase_hint".local(),
                message: error,
                actions: [
                    CCAlertAction(title: "common.confirm".local(), role: .default) {
                        purchase.purchaseError = nil
                    },
                ]
            )
            purchase.purchaseError = nil
        }
    }

    // MARK: - Header

    private var topBar: some View {
        HStack {
            CCDesigin.GlassIconButton(icon: PikaIcon.Name.close) {
                AppHelper.shared.mada(.soft)
                if isPaywall { onSkip?() } else { dismiss() }
            }
            Spacer(minLength: 0)
            #if DEBUG
            if isPaywall {
                Button {
                    AppHelper.shared.mada(.soft)
                    PurchaseManager.shared.debugUnlockPremium()
                } label: {
                    Text("DEBUG 通过")
                        .ccText(font: .cc.smBold, color: .cc.primaryForeground)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(Color.cc.primary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            #endif
        }
        .opacity(vm.showEntrance ? 1 : 0)
        .offset(y: vm.showEntrance ? 0 : -14)
    }

    private var heading: some View {
        VStack(spacing: 8) {
            Text((isWinback ? "store.paywall.winback.title" : "store.paywall.title").local())
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.cc.foreground)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text((isWinback ? "store.paywall.winback.subtitle" : "store.paywall.subtitle").local())
                .ccText(font: .cc.sm, color: .cc.mutedForeground)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .opacity(vm.showEntrance ? 1 : 0)
        .offset(y: vm.showEntrance ? 0 : 14)
    }

    // MARK: - Hero

    private var heroAssetName: String { isWinback ? "buy-winback" : "buy" }

    private var heroImage: some View {
        let aspect: CGFloat = {
            guard let img = UIImage(named: heroAssetName), img.size.width > 0 else { return 1086.0 / 1448.0 }
            return img.size.height / img.size.width
        }()

        return ZStack {
            Group {
                if let uiImage = UIImage(named: heroAssetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                } else {
                    Color.cc.muted.opacity(0.35)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1 / aspect, contentMode: .fit)
                }
            }

            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: Color.cc.background, location: 0),
                        .init(color: Color.cc.background.opacity(0.85), location: 0.3),
                        .init(color: Color.cc.background.opacity(0.35), location: 0.65),
                        .init(color: Color.cc.background.opacity(0), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 88)
                Spacer(minLength: 0)
                LinearGradient(
                    stops: [
                        .init(color: Color.cc.background.opacity(0), location: 0),
                        .init(color: Color.cc.background.opacity(0.55), location: 0.4),
                        .init(color: Color.cc.background.opacity(0.9), location: 0.75),
                        .init(color: Color.cc.background, location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 104)
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1 / aspect, contentMode: .fit)
        .opacity(vm.showEntrance ? 1 : 0)
    }

    /// 硬墙专用：插图底缘与上方 hero 同构负 padding，吃掉 buy 资产自带的空白
    private var trialContinueHint: some View {
        Text("store.paywall.cta.trial_continue".local())
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(Color.cc.foreground)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .opacity(vm.showEntrance ? 1 : 0)
            .offset(y: vm.showEntrance ? 0 : 14)
    }

    /// 挽回专用：插图底缘「仅此一次」
    private var winbackOfferHint: some View {
        Text("store.paywall.winback.offer".local())
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(Color.cc.foreground)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .opacity(vm.showEntrance ? 1 : 0)
            .offset(y: vm.showEntrance ? 0 : 14)
    }

    // MARK: - Plans

    private var plans: some View {
        VStack(spacing: 12) {
            planButton(
                tier: .annual,
                fractal: .julia,
                cap: isWinback ? "store.paywall.winback.badge".local() : "store.paywall.badge".local(),
                title: vm.annualTitle,
                subtitle: vm.annualPerMonthLine,
                height: 86
            )
            if !isWinback {
                planButton(
                    tier: .monthly,
                    fractal: .newton,
                    cap: nil,
                    title: vm.monthlyTitle,
                    subtitle: vm.monthlySubtitle,
                    height: 72
                )
            }
        }
        .opacity(vm.showEntrance ? 1 : 0)
        .offset(y: vm.showEntrance ? 0 : 16)
    }

    private func planButton(
        tier: SubscriptionPlanTier,
        fractal: PaywallFractalKind,
        cap: String?,
        title: String,
        subtitle: String,
        height: CGFloat
    ) -> some View {
        let selected = vm.selectedTier == tier
        return Button {
            AppHelper.shared.mada(.selection)
            vm.select(tier)
        } label: {
            SubscriptionPlanKeycap(selected: selected, fractal: fractal, cap: cap) {
                HStack(spacing: 12) {
                    SubscriptionPlanRadio(selected: selected)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .ccText(font: .cc.baseBold, color: .cc.foreground)
                            .shadow(color: .white.opacity(0.5), radius: 0, x: 0, y: 1)
                        Text(subtitle)
                            .ccText(font: .cc.sm, color: .cc.mutedForeground)
                    }
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 16)
                .frame(height: height)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA / Footer

    private var purchaseButton: some View {
        Button {
            Task { await vm.purchaseSelected() }
        } label: {
            Group {
                if purchase.isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.cc.background))
                } else {
                    VStack(spacing: 2) {
                        Text(vm.ctaPrimaryTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.cc.background)
                        if let secondary = vm.ctaSecondaryTitle {
                            Text(secondary)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.cc.background.opacity(0.72))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.cc.foreground, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!vm.canPurchase)
        .opacity(vm.canPurchase ? 1 : 0.55)
        .opacity(vm.showEntrance ? 1 : 0)
    }

    private var skipButton: some View {
        Button {
            AppHelper.shared.mada(.soft)
            onSkip?()
        } label: {
            Text("store.paywall.winback.skip".local())
                .ccText(font: .cc.base, color: .cc.mutedForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.plain)
        .opacity(vm.showEntrance ? 1 : 0)
    }

    private var footerLinks: some View {
        HStack(spacing: 8) {
            link("store.paywall.terms".local(), action: vm.openTerms)
            Text("·").ccText(font: .cc.sm, color: .cc.mutedForeground)
            link("store.restore_purchase".local()) { Task { await vm.restore() } }
            Text("·").ccText(font: .cc.sm, color: .cc.mutedForeground)
            link("store.redeem".local(), action: vm.redeem)
        }
        .frame(maxWidth: .infinity)
        .opacity(vm.showEntrance ? 1 : 0)
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .ccText(font: .cc.sm, color: .cc.mutedForeground)
                .underline()
        }
        .buttonStyle(.plain)
    }

    private var underText: some View {
        Text(subscriptionTerms)
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(Color.cc.mutedForeground.opacity(0.7))
            .tint(Color.cc.foreground)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                MainViewModel.shared.pushPageSheet(view: InAppBrowser(url: url))
                return .handled
            })
            .opacity(vm.showEntrance ? 1 : 0)
    }

    private var subscriptionTerms: AttributedString {
        (try? AttributedString(markdown: "store.subscription_terms".local()))
            ?? AttributedString("store.subscription_terms".local())
    }
}

#Preview {
    VipBuyView()
}

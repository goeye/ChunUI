#if canImport(UIKit)
/**
 * [INPUT]: 依赖 Color.cc/Font.cc、CCSheetChrome、CCNeoButton、CCDesigin.GlassIconButton、PikaIcon
 * [OUTPUT]: 对外提供 CCAlertCenter / CCBottomAlertView / CCAlertWindow——顶层沉底 Alert（屏边 8pt、可点）
 * [POS]: DesignSystem/Compents 的确认弹层真相源；与 CCToastWindow 同属顶层覆盖窗范式（alert+2）；
 *        AppHelper.showAlert/showBottomAlert 唯一出口；present 时先 dismissKeyboard；禁止 UIAlertController / SwiftUI .alert
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Combine
import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 模型
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCAlertAction: Identifiable {
    public enum Role {
        case `default`     // 近黑主按钮
        case destructive   // 危险红
        case secondary     // 次要灰底（取消）
    }

    public let id = UUID()
    let title: String
    let role: Role
    let handler: (() -> Void)?

    public init(title: String, role: Role = .default, handler: (() -> Void)? = nil) {
        self.title = title
        self.role = role
        self.handler = handler
    }
}

public struct CCAlertRequest: Identifiable, Equatable {
    public let id = UUID()
    let title: String
    let message: String?
    let actions: [CCAlertAction]

    public static func == (lhs: CCAlertRequest, rhs: CCAlertRequest) -> Bool {
        lhs.id == rhs.id
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCAlertCenter
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCAlertCenter: ObservableObject {
    public static let shared = CCAlertCenter()

    @Published private(set) var current: CCAlertRequest?

    private init() {}

    public func present(title: String, message: String? = nil, actions: [CCAlertAction]) {
        AppHelper.shared.dismissKeyboard()
        AppHelper.shared.mada(.soft)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            current = CCAlertRequest(title: title, message: message, actions: actions)
        }
    }

    public func dismiss() {
        withAnimation(.easeOut(duration: 0.22)) {
            current = nil
        }
    }

    func perform(_ action: CCAlertAction) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            action.handler?()
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCBottomAlertView（屏边 8pt；下角同心屏圆角）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCBottomAlertView: View {
    @ObservedObject private var center = CCAlertCenter.shared

    /// 卡片到物理屏底 / 左右的铁律边距
    private let edgeInset: CGFloat = 8

    private var cardShape: UnevenRoundedRectangle {
        CCSheetChrome.floatingShape(edgeInset: edgeInset)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            if center.current != nil {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { center.dismiss() }
                    .transition(.opacity)
            }

            if let alert = center.current {
                alertCard(alert)
                    .padding(.horizontal, edgeInset)
                    .padding(.bottom, edgeInset)
                    // 8pt 相对物理屏底，不吃 Home Indicator 安全区
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(true)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(center.current != nil)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: center.current?.id)
    }

    private func alertCard(_ alert: CCAlertRequest) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(alert.title)
                    .font(.cc.lgBold)
                    .foregroundStyle(Color.cc.foreground)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                CCDesigin.GlassIconButton(
                    icon: PikaIcon.Name.close,
                    tint: .cc.mutedForeground,
                    size: .small
                ) {
                    AppHelper.shared.mada(.soft)
                    center.dismiss()
                }
                .accessibilityLabel(CCStrings.current.cancel)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            if let message = alert.message, !message.isEmpty {
                Text(message)
                    .font(.cc.base)
                    .foregroundStyle(Color.cc.mutedForeground)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
            }

            if !alert.actions.isEmpty {
                actionBar(alert.actions)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
            } else {
                Spacer().frame(height: 16)
            }
        }
        .background(Color.cc.card, in: cardShape)
        .clipShape(cardShape)
        .shadow(color: Color.cc.shadow.opacity(0.18), radius: 24, y: 8)
    }

    @ViewBuilder
    private func actionBar(_ actions: [CCAlertAction]) -> some View {
        // 1–2 钮横排；3+ 竖排（未保存三选一等）
        if actions.count <= 2 {
            HStack(spacing: 10) {
                ForEach(actions) { action in
                    neoButton(for: action)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(actions) { action in
                    neoButton(for: action)
                }
            }
        }
    }

    private func neoButton(for action: CCAlertAction) -> some View {
        CCNeoButton(
            action.title,
            variant: neoVariant(for: action.role),
            size: .large,
            fullWidth: true,
            accent: action.role == .default ? Color.cc.foreground : nil
        ) {
            center.perform(action)
        }
    }

    private func neoVariant(for role: CCAlertAction.Role) -> CCNeoVariant {
        switch role {
        case .destructive: return .danger
        case .default: return .primary
        // secondary 实底同 card 会糊边；outline 在 Alert 卡面上才有边界
        case .secondary: return .outline
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCAlertHitWindow（无 Alert → hitTest nil 穿透；有 Alert → 正常命中）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 禁止「hit == rootView 则穿透」的旧 PassThrough 写法——iOS 18+ UIHostingController 会吃掉按钮命中。
private final class CCAlertHitWindow: UIWindow {
    /// 由 CCAlertWindow 同步；hitTest 不碰 @MainActor 单例，避并发告警
    var hasPresentedAlert = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard hasPresentedAlert else { return nil }
        return super.hitTest(point, with: event)
    }
}

@MainActor
public final class CCAlertWindow {
    public static let shared = CCAlertWindow()
    private var window: CCAlertHitWindow?
    private var cancellable: AnyCancellable?

    private init() {}

    public func attach(to scene: UIWindowScene) {
        guard window == nil else { return }
        let alertWindow = CCAlertHitWindow(windowScene: scene)
        // toast = alert+1；Alert 必须盖在 toast 之上
        alertWindow.windowLevel = UIWindow.Level.alert + 2
        alertWindow.backgroundColor = .clear
        alertWindow.isUserInteractionEnabled = true

        let hosting = UIHostingController(rootView: CCBottomAlertView())
        hosting.view.backgroundColor = .clear
        hosting.view.isOpaque = false
        alertWindow.rootViewController = hosting
        alertWindow.isHidden = false
        window = alertWindow

        cancellable = CCAlertCenter.shared.$current
            .receive(on: RunLoop.main)
            .sink { [weak alertWindow] current in
                alertWindow?.hasPresentedAlert = current != nil
            }
    }
}

#Preview("沉底 Alert") {
    ZStack {
        Color.cc.background.ignoresSafeArea()
        CCBottomAlertView()
            .onAppear {
                CCAlertCenter.shared.present(
                    title: "Cancel Post?",
                    message: "You are about to abandon your post. If you would like to save it for later, save it as a draft.",
                    actions: [
                        CCAlertAction(title: "删除", role: .destructive),
                        CCAlertAction(title: "Save Draft", role: .default),
                    ]
                )
            }
    }
}

#endif

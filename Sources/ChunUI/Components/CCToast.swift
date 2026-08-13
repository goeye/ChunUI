//
//  CCToast.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 PikaIcon、AqiBubbleTail、Color.cc/Font.cc 设计令牌与 CCUploadToast（上传进度胶囊，同窗合流）；气泡路由锚点由 MainTabbar 上报 advisorAvatarAnchor
 * [OUTPUT]: 对外提供 CCToastCenter 单例（info/success/warning/error/loading 单槽消息事实源 + Route 双路由：capsule 顶部胶囊 / aqiBubble 阿奇头像气泡）、CCToastView 玻璃胶囊 toast、CCAqiBubbleToast（iMessage 式气泡：尖尾指向 tabbar 阿奇头像、X 关闭、点外即关）、CCKeyboardWatcher 键盘可见性单例与 CCToastWindow 置顶窗口（alert+1 级；胶囊态触摸全透传，气泡态接管触摸实现点外关闭）
 * [POS]: DesignSystem/Compents 的全应用 toast 唯一系统——AppHelper.pushNotification 的唯一出口（路由判定在 AppHelper），全自研零第三方；SceneDelegate 挂载 CCToastWindow
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Combine
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCToastCenter（单槽消息事实源：新 toast 顶换旧 toast，loading 常驻至被替换）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCToastCenter: ObservableObject {
    public static let shared = CCToastCenter()

    public enum Kind {
        case info
        case success
        case warning
        case error
        case loading
    }

    /// 呈现路由：顶部玻璃胶囊（缺省）/ tabbar 阿奇头像气泡（一级页面专属，锚点为头像全局 frame）
    public enum Route: Equatable {
        case capsule
        case aqiBubble(anchor: CGRect)
    }

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let kind: Kind
        let message: String
        let route: Route
    }

    @Published private(set) var current: Toast?
    /// tabbar 阿奇头像的全局 frame（MainTabbar 持续上报），气泡路由的锚点事实源
    public var advisorAvatarAnchor: CGRect = .null
    private var hideTask: Task<Void, Never>?

    private init() {}

    public func show(_ kind: Kind, _ message: String, route: Route = .capsule) {
        hideTask?.cancel()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            current = Toast(kind: kind, message: message, route: route)
        }
        // loading 常驻等待被结果 toast 顶换，15s 安全阀防悬挂；错误多停留一拍
        let duration: Double = switch kind {
        case .loading: 15
        case .error: 3.2
        default: 2.4
        }
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.22)) {
                current = nil
            }
        }
    }

    public func dismiss() {
        hideTask?.cancel()
        withAnimation(.easeOut(duration: 0.22)) {
            current = nil
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 语义图标槽（胶囊与气泡共用，DRY）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCToastIconSlot: View {
    let kind: CCToastCenter.Kind

    var body: some View {
        switch kind {
        case .info:
            PikaIcon("information-circle", size: 15, color: .cc.foreground)
        case .success:
            PikaIcon("check-tick-circle", size: 15, color: .cc.success)
        case .warning:
            PikaIcon("alert-triangle", size: 15, color: .cc.foreground)
        case .error:
            PikaIcon("alert-circle", size: 15, color: .cc.destructive)
        case .loading:
            ProgressView()
                .controlSize(.small)
                .tint(.cc.foreground)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCToastView（玻璃胶囊：语义图标 + sm 粗体文案，顶部弹入回弹退出）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCToastView: View {
    @ObservedObject private var center = CCToastCenter.shared

    public var body: some View {
        if let toast = center.current, toast.route == .capsule {
            HStack(spacing: 8) {
                CCToastIconSlot(kind: toast.kind)
                Text(toast.message)
                    .ccText(font: .cc.baseBold, color: .cc.foreground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 40)
            .background(Color.cc.card, in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.cc.border.opacity(0.8), lineWidth: CGFloat.cc.hairline)
            }
            .shadow(color: Color.cc.shadow.opacity(0.12), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 32)
            .transition(
                .move(edge: .top)
                    .combined(with: .opacity)
                    .combined(with: .scale(scale: 0.94, anchor: .top))
            )
            .id(toast.id)   // 顶换时旧退新进，而非原地改字
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCAqiBubbleToast（阿奇气泡：iMessage 式从头像左上方弹出，尖尾指头像）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCAqiBubbleToast: View {
    @ObservedObject private var center = CCToastCenter.shared

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                if let toast = center.current, case .aqiBubble(let anchor) = toast.route {
                    // 点击气泡外任意处即关（触摸由 CCToastWindow 在气泡态接管）
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { center.dismiss() }

                    bubble(for: toast)
                        // 气泡右缘压在头像左上角内侧，尖尾自然落在头像左上方
                        .padding(.trailing, max(12, geo.size.width - anchor.minX - 26))
                        .padding(.bottom, max(0, geo.size.height - anchor.minY + 4))
                        .transition(
                            .scale(scale: 0.1, anchor: .bottomTrailing)
                                .combined(with: .opacity)
                        )
                        .id(toast.id)   // 顶换时旧退新进
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .ignoresSafeArea()
    }

    /// 阿奇说的一句话：语义图标 + 正文字号消息 + X 关闭钮，卡片白底 + 尖尾
    private func bubble(for toast: CCToastCenter.Toast) -> some View {
        HStack(alignment: .center, spacing: 10) {
            CCToastIconSlot(kind: toast.kind)
            Text(toast.message)
                .ccText(font: .cc.base, color: .cc.foreground)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
            closeButton
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .background(Color.cc.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.cc.border.opacity(0.8), lineWidth: CGFloat.cc.hairline)
        }
        .overlay(alignment: .bottomTrailing) {
            AqiBubbleTail()
                .fill(Color.cc.card)
                .frame(width: 16, height: 10)
                .offset(x: -10, y: 9)
        }
        .shadow(color: Color.cc.shadow.opacity(0.14), radius: 12, x: 0, y: 5)
        .frame(maxWidth: 300, alignment: .trailing)
    }

    private var closeButton: some View {
        Button {
            CCToastCenter.shared.dismiss()
        } label: {
            PikaIcon(PikaIcon.Name.close, size: 13, color: .cc.mutedForeground)
                .frame(width: 28, height: 28)
                .background(Color.cc.muted, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCKeyboardWatcher（键盘可见性单例：气泡路由判定 + MainView 常驻区让位共用）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCKeyboardWatcher: ObservableObject {
    public static let shared = CCKeyboardWatcher()

    @Published public private(set) var isVisible = false
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false })
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in self?.isVisible = visible }
            .store(in: &cancellables)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCToastWindow（置顶窗口：胶囊态触摸全透传，气泡态接管触摸点外即关）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCToastWindow {
    public static let shared = CCToastWindow()
    private var window: UIWindow?

    private init() {}

    public func attach(to scene: UIWindowScene) {
        guard window == nil else { return }
        let toastWindow = AqiBubbleHitWindow(windowScene: scene)
        toastWindow.windowLevel = UIWindow.Level.alert + 1
        toastWindow.backgroundColor = .clear

        let hosting = UIHostingController(rootView: CCToastRoot())
        hosting.view.backgroundColor = .clear
        toastWindow.rootViewController = hosting
        toastWindow.isHidden = false
        window = toastWindow
        // 键盘观察必须随窗口启动即在岗：首次 toast 时才建单例会漏掉已弹出的键盘
        _ = CCKeyboardWatcher.shared
    }
}

/// 触摸策略窗口：仅当气泡 toast 在场时接收触摸（承载点外即关 + X 钮），
/// 胶囊/上传进度 toast 纯展示，所有手势透传底层窗口
private final class AqiBubbleHitWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let toast = CCToastCenter.shared.current, case .aqiBubble = toast.route else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// 窗口根视图：上传进度条与胶囊 toast 纵向合流钉顶，气泡 toast 锚定 tabbar 阿奇头像
private struct CCToastRoot: View {
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                CCUploadToast()
                CCToastView()
                Spacer(minLength: 0)
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity)

            CCAqiBubbleToast()
        }
    }
}

#if canImport(UIKit)
/**
 * [INPUT]: 依赖 UIKit / SwiftUI UIViewRepresentable
 * [OUTPUT]: 对外提供 CCZoomID、ZoomAnchorRegistry、CCZoom.transition(sourceID:)、.ccZoomSource(id:) / .ccZoomDestination(id:)
 * [POS]: DesignSystem/Compents 的 UIKit←SwiftUI Zoom 英雄转场锚点基建；配合 MainViewModel.pushZoom / presentZoom 与 CCSheetConfig.zoom(from:)
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

/// 稳定 Zoom 锚点 id（动态实体用业务 id：prospect.id / memPost.id）
public enum CCZoomID {
    /// 约会 tab「+」发帖入口
    public static let memPostComposer = "zoom.mempost.composer"
    /// 对象 tab 页头「+」建档入口
    public static let addProspect = "zoom.prospect.add"
    /// 分析 tab 聊天截图分析卡 → 全屏分析页
    public static let screenshotAnalysis = "zoom.analysis.screenshot"
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Zoom 转场工厂（push / present / pageSheet 唯一装配口）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCZoom {
    /// 按 sourceID 装配 UIKit Zoom 英雄转场；source 不在场时系统自动降级默认转场
    @MainActor
    public static func transition(sourceID: String) -> UIViewController.Transition {
        let options = UIViewController.Transition.ZoomOptions()
        options.alignmentRectProvider = { context in
            guard let host = context.zoomedViewController.view else { return .zero }
            return ZoomAnchorRegistry.shared.destinationRect(id: sourceID, in: host)
                ?? host.bounds
        }
        return .zoom(options: options) { _ in
            ZoomAnchorRegistry.shared.sourceView(id: sourceID)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ZoomAnchorRegistry（按 id 弱引用登记 source / destination UIView）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class ZoomAnchorRegistry {
    public static let shared = ZoomAnchorRegistry()

    private var sources: [String: WeakViewBox] = [:]
    private var destinations: [String: WeakViewBox] = [:]

    private init() {}

    func registerSource(id: String, view: UIView) {
        sources[id] = WeakViewBox(view)
        prune()
    }

    func registerDestination(id: String, view: UIView) {
        destinations[id] = WeakViewBox(view)
        prune()
    }

    func unregisterSource(id: String, view: UIView) {
        if sources[id]?.view === view { sources[id] = nil }
    }

    func unregisterDestination(id: String, view: UIView) {
        if destinations[id]?.view === view { destinations[id] = nil }
    }

    func sourceView(id: String) -> UIView? {
        prune()
        return sources[id]?.view
    }

    /// 主卡 destination 在 hosting VC 坐标系下的 alignmentRect；无锚点时返回 nil
    func destinationRect(id: String, in hostView: UIView) -> CGRect? {
        prune()
        guard let anchor = destinations[id]?.view, anchor.window != nil else { return nil }
        return anchor.convert(anchor.bounds, to: hostView)
    }

    private func prune() {
        sources = sources.filter { $0.value.view != nil }
        destinations = destinations.filter { $0.value.view != nil }
    }
}

private final class WeakViewBox {
    weak var view: UIView?
    public init(_ view: UIView) { self.view = view }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Anchor UIViewRepresentable
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private enum ZoomAnchorKind {
    case source
    case destination
}

private struct ZoomAnchorView: UIViewRepresentable {
    let id: String
    let kind: ZoomAnchorKind

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.isOpaque = false
        register(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        register(uiView)
    }

    public static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // id 在 dismantle 不可得；由 Weak 剪枝即可
    }

    private func register(_ view: UIView) {
        switch kind {
        case .source:
            ZoomAnchorRegistry.shared.registerSource(id: id, view: view)
        case .destination:
            ZoomAnchorRegistry.shared.registerDestination(id: id, view: view)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - View 修饰符
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct ZoomSourceModifier: ViewModifier {
    let id: String

    func body(content: Content) -> some View {
        content
            .background {
                ZoomAnchorView(id: id, kind: .source)
            }
    }
}

private struct ZoomDestinationModifier: ViewModifier {
    let id: String

    func body(content: Content) -> some View {
        content
            .background {
                ZoomAnchorView(id: id, kind: .destination)
            }
    }
}

extension View {
    /// 登记 Zoom 转场起点（列表头像 / 大卡封面）；id 与 pushZoom/presentZoom(sourceID:) 同值
    public func ccZoomSource(id: String) -> some View {
        modifier(ZoomSourceModifier(id: id))
    }

    /// 登记 Zoom 转场落点 alignmentRect（个人主页主卡 / 帖子详情 / 发帖页）
    public func ccZoomDestination(id: String) -> some View {
        modifier(ZoomDestinationModifier(id: id))
    }

    /// zoomID 为 nil 时无锚点（纯 .sheet 编辑流）
    @ViewBuilder
    public func ccZoomDestination(id: String?) -> some View {
        if let id {
            ccZoomDestination(id: id)
        } else {
            self
        }
    }
}

#endif

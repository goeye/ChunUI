/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCImages.swift                                   ║
 * ║                         图片展示组件库                                      ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: 主题 Color.cc、shimmer、URLSession(URLCache)；可选宿主注入 CCImageLoader.custom / 宿主资产 avatar-default
 * [OUTPUT]: CCAvatarMedia、CCImageRole、CCWebImage（avatar 加载=缺省图铺满；media 内缩灰块）、UserAvatar、CCAvatarFallback、CCImageLoadingPlaceholder
 * [POS]: Components 图片组件；零第三方——内建 URLCache 加载器（内存 64M/磁盘 512M + 3 次重试 + 0.3s 渐显），宿主要用 Kingfisher 等可经 CCImageLoader.custom 整体接管
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 头像 URL 语义（空 / CDN 旧缺省 → 本地 avatar-default）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCAvatarMedia {
    /// 无有效头像：空串，或与宿主声明的缺省头像 URL 相同
    public static func isPlaceholder(_ url: String?) -> Bool {
        guard let raw = url?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return true
        }
        if !ChunUI.defaultAvatarURL.isEmpty, raw == ChunUI.defaultAvatarURL { return true }
        if raw.hasSuffix("/assets/avatar-default.png") { return true }
        return false
    }
}

/// 网络图角色：头像必须圆形语义下缺省/加载铺满；内容图保持内缩灰块
public enum CCImageRole {
    case media
    case avatar
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 加载器（零第三方；宿主可整体接管）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCImageLoader {
    /// 宿主自定义远程图渲染（如 Kingfisher）：注入后 CCWebImage 的远程分支整体走这里。
    /// 返回视图需自行处理占位/裁切；包内仍负责 avatar 角色的外层圆形裁切。
    nonisolated(unsafe) public static var custom: ((URL, CCImageRole) -> AnyView)?

    /// URL 归一钩子：CCWebImage 取 URL 前先过此函数（宿主可做历史死域名重写）
    nonisolated(unsafe) public static var urlNormalizer: ((String) -> String)?

    /// 内建缓存会话：URLCache 内存 64MB / 磁盘 512MB
    nonisolated static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 512 * 1024 * 1024
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
}

/// 内建远程图视图：URLCache 命中即出图，未中则拉取（3 次退避重试 + 0.3s 渐显）
public struct CCRemoteImage: View {
    let url: URL?
    var role: CCImageRole = .media

    @State private var loaded: UIImage?

    public var body: some View {
        Group {
            if let ui = loaded {
                Image(uiImage: ui)
                    .resizable()
            } else {
                CCImageLoadingPlaceholder(role: role)
                    .shimmer()
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { return }
        for attempt in 0 ..< 3 {
            if let (data, _) = try? await CCImageLoader.session.data(from: url),
               let ui = UIImage(data: data) {
                withAnimation(.easeIn(duration: 0.3)) { loaded = ui }
                return
            }
            try? await Task.sleep(nanoseconds: UInt64(300_000_000 * (attempt + 1)))
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 加载占位
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// media：浅灰块内缩；avatar：本地缺省头像铺满（由外层 Circle clip）
public struct CCImageLoadingPlaceholder: View {
    public var role: CCImageRole = .media
    /// media 相对短边的内缩比例
    public var insetRatio: CGFloat = 0.12

    public init(role: CCImageRole = .media, insetRatio: CGFloat = 0.12) {
        self.role = role
        self.insetRatio = insetRatio
    }

    public var body: some View {
        switch role {
        case .avatar:
            CCAvatarFallback()
        case .media:
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                let inset = max(4, side * insetRatio)
                RoundedRectangle(cornerRadius: max(4, inset * 0.4), style: .continuous)
                    .fill(Color.cc.muted)
                    .padding(inset)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 网络图片组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCWebImage: View {
        public let str: String
        public var role: CCImageRole = .media

        public init(str: String, role: CCImageRole = .media) {
            self.str = str
            self.role = role
        }

        private var trimmed: String {
            str.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private var isLocalAsset: Bool {
            !trimmed.hasPrefix("http://") &&
                !trimmed.hasPrefix("https://") &&
                !trimmed.contains("://")
        }

        private var url: URL? {
            URL(string: CCImageLoader.urlNormalizer?(trimmed) ?? trimmed)
        }

        public var body: some View {
            Group {
                if trimmed.isEmpty {
                    CCImageLoadingPlaceholder(role: role)
                } else if CCAvatarMedia.isPlaceholder(trimmed) {
                    // CDN 旧缺省 → 本地缺省头像，禁再拉远程 SF 拼凑图
                    CCAvatarFallback()
                } else if isLocalAsset {
                    Image(trimmed)
                        .resizable()
                        .modifier(CCAvatarFillIfNeeded(role: role))
                } else if let custom = CCImageLoader.custom, let url {
                    custom(url, role)
                        .modifier(CCAvatarFillIfNeeded(role: role))
                } else {
                    CCRemoteImage(url: url, role: role)
                        .modifier(CCAvatarFillIfNeeded(role: role))
                }
            }
        }
    }
}

private struct CCAvatarFillIfNeeded: ViewModifier {
    let role: CCImageRole
    @ViewBuilder
    func body(content: Content) -> some View {
        if role == .avatar {
            content.scaledToFill()
        } else {
            content
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 用户头像组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct UserAvatar: View {
        public let str: String
        public let userId: String
        public let size: CGFloat

        public init(str: String, userId: String, size: CGFloat = 56.0) {
            self.str = str
            self.userId = userId
            self.size = size
        }

        public var body: some View {
            Group {
                if CCAvatarMedia.isPlaceholder(str) {
                    CCAvatarFallback()
                } else {
                    CCDesigin.CCWebImage(str: str, role: .avatar)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 无头像缺省（宿主资产 avatar-default 优先，SF 人形兜底）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 无头像缺省：宿主 Assets 若含 `avatar-default` 则铺满（外层必须 clipShape(Circle())），
/// 否则灰底 + SF 人形——保证包在任何宿主里开箱不裂
public struct CCAvatarFallback: View {
    /// SF 兜底图标尺寸；宿主资产在场时无效
    public var iconSize: CGFloat = 18

    public init(iconSize: CGFloat = 18) {
        self.iconSize = iconSize
    }

    public var body: some View {
        if let ui = UIImage(named: "avatar-default") {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ZStack {
                Color.cc.muted
                Image(systemName: "person.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(Color.cc.mutedForeground)
            }
        }
    }
}

/**
 * [INPUT]: 无依赖（纯值结构）
 * [OUTPUT]: 对外提供 CCStrings —— 组件内建文案的可覆写表（默认英文）
 * [POS]: Core 的文案配置；替代宿主 App 的 String Catalog 依赖，组件禁止直连 String(localized:)
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Foundation

/// 组件内建文案表。宿主经 `ChunUI.configure(strings:)` 覆写做本地化。
nonisolated public struct CCStrings: Sendable {
    // ── 通用动作 ──
    public var cancel = "Cancel"
    public var confirm = "OK"
    public var done = "Done"
    public var save = "Save"
    public var discard = "Discard"
    public var retry = "Retry"

    // ── 状态 ──
    public var loading = "Loading…"
    public var loadFailed = "Failed to load"
    public var empty = "Nothing here yet"

    // ── 列表加载 ──
    public var loadingMore = "Loading more…"
    public var noMoreData = "No more"
    public var loadMore = "Load more"
    public var pageLoadFailed = "Page failed to load"

    // ── 相机权限 ──
    public var cameraPermissionTitle = "Camera access needed"
    public var cameraPermissionSubtitle = "Enable camera access in Settings to take photos."
    public var openSettings = "Open Settings"

    // ── 品牌 ──
    public var appName = "ChunUI"

    // ── 编辑 sheet ──
    public var unsavedTitle = "Unsaved changes"
    public var unsavedMessage = "Save your edits before leaving?"
    public var keepEditing = "Keep editing"

    public init() {}

    /// 当前生效文案表（ChunUI.configure 写入）
    nonisolated(unsafe) public static var current = CCStrings()
}

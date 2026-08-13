/**
 * [INPUT]: 依赖 ChunUIDemo 的 ChunUIGalleryRoot
 * [OUTPUT]: 对外提供画廊示例 App 入口
 * [POS]: Example 工程唯一源文件；组件展示逻辑全在包内 ChunUIDemo
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import ChunUIDemo
import SwiftUI

@main
struct GalleryApp: App {
    var body: some Scene {
        WindowGroup {
            ChunUIGalleryRoot()
        }
    }
}

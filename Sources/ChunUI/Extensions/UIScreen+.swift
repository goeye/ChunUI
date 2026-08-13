//
//  UIScreen+.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 UIKit UIApplication.connectedScenes
 * [OUTPUT]: 对外提供 UIScreen.cc_active——前台活跃场景屏幕
 * [POS]: Core/Extensions 的取屏唯一出口；iOS 26 弃用 UIScreen.main 后全应用一律经此，禁止再写 UIScreen.main
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import UIKit

extension UIScreen {
    /// UIScreen.main 的迁移出口：前台活跃场景优先，其次任一已连接场景；理论兜底空 screen
    public static var cc_active: UIScreen {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return scene?.screen ?? UIScreen()
    }
}

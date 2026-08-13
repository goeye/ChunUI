//
//  CCTrackSeam.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 SwiftUI simultaneousGesture
 * [OUTPUT]: 对外提供 CCTrack.onTap 接线座（Core/ZTrack 启动时注入实现）与 .ccTrackTap(_:) 修饰符——设计系统原子按钮的组件级自动埋点唯一通道
 * [POS]: DesignSystem/Compents 的埋点依赖倒置座：DesignSystem 保持零业务依赖，只持有一个默认空实现的闭包；原子（Button/GlassIconButton/CCNeoButton/CCSettingRow/MainTabbar…）在动作点调用，永不感知埋点实现
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

/// 埋点接线座（DIP）：ZTrack.start() 注入真实实现；未注入时为空操作
public enum CCTrack {
    @MainActor public static var onTap: (_ element: String) -> Void = { _ in }
}

extension View {
    /// 组件级点击埋点：与既有手势并行，不抢占不拦截
    func ccTrackTap(_ element: String) -> some View {
        simultaneousGesture(TapGesture().onEnded { CCTrack.onTap(element) })
    }
}

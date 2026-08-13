//
//  CCMotion.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 SwiftUI Animation / AnyTransition
 * [OUTPUT]: 对外提供 CCMotion 全局动画令牌（Laper Reveal 纲领：timingCurve(0.22,0.8,0.36,1) 0.32s 零过冲 + 0.07s index 错峰）与 ccReveal 差值入场修饰符；wave 波浪族（spring 0.6/0.8 微过冲 + 0.13s 宽错峰 + 26pt 行程 + 0.96 微缩放）与 ccWaveReveal 供选项列表级联；pageSwitch + AnyTransition.ccPageRise（tab 页切换微升丝滑转场，MainView / ProspectDetailView 消费）
 * [POS]: DesignSystem/Theme 的动画统一真相源——一切列表/选项入场走 ccReveal，禁止各页自写 reveal 曲线
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

public enum CCMotion {
    /// Laper Reveal：快出缓收零过冲
    public static let reveal = Animation.timingCurve(0.22, 0.8, 0.36, 1, duration: 0.32)
    /// index 错峰步长
    public static let staggerStep = 0.07

    public static func reveal(index: Int) -> Animation {
        reveal.delay(Double(index) * staggerStep)
    }

    /// 波浪 Reveal：行程更长、错峰更宽、弹簧微过冲——选项逐个「涌」入而非闪现
    public static let wave = Animation.spring(response: 0.6, dampingFraction: 0.8)
    /// 波浪错峰步长（比 reveal 宽近一倍，波峰肉眼可辨）
    public static let waveStaggerStep = 0.13

    public static func wave(index: Int) -> Animation {
        wave.delay(Double(index) * waveStaggerStep)
    }

    /// tab 页切换：零过冲快出缓收，与 reveal 同族曲线
    public static let pageSwitch = Animation.timingCurve(0.22, 0.8, 0.36, 1, duration: 0.34)
}

extension AnyTransition {
    /// 页面微升入场：新页从下方 12pt 淡入，旧页原地淡出——「微微」即止，禁止大位移
    public static var ccPageRise: AnyTransition {
        .asymmetric(
            insertion: .offset(y: 12).combined(with: .opacity),
            removal: .opacity
        )
    }
}

extension View {
    /// index 差值入场：opacity 0→1 / y 14→0，按 index 错峰
    public func ccReveal(_ shown: Bool, index: Int) -> some View {
        self
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .animation(CCMotion.reveal(index: index), value: shown)
    }

    /// 波浪差值入场：opacity 0→1 / y 26→0 / scale 0.96→1，宽错峰弹簧——列表如波浪逐行涌起
    public func ccWaveReveal(_ shown: Bool, index: Int) -> some View {
        self
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 26)
            .scaleEffect(shown ? 1 : 0.96, anchor: .top)
            .animation(CCMotion.wave(index: index), value: shown)
    }
}

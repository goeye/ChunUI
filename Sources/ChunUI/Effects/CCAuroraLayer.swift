//
//  CCAuroraLayer.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 SwiftUI TimelineView、CCShaders.aurora（DesignSystem/Shader/Aurora.metal）、Color.cc 与 Color.toRGB()
 * [OUTPUT]: 对外提供 CCAuroraLayer（AI 工作时屏幕底部全宽极光层，占屏高约 1/2，明亮粉系固定停靠色，不可见时暂停时间轴零开销；相位累计器保证暂停/恢复零跳变）
 * [POS]: DesignSystem/Effects 的 AI 工作态视觉原子，不知道任何业务状态；由 Advisor 聊天、Learn 截图分析与 Auth 收银氛围层注入 visible，三个 Feature 禁止复制 Shader 实现
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

/// 屏幕底部全宽极光：AI 流式工作时淡入，收尾淡出
public struct CCAuroraLayer: View, Equatable {
    /// 是否可见（绑定聊天流式状态）
    let visible: Bool

    var amplitude: Float = 0.7
    var blend: Float = 0.55
    var speed: Float = 1.6
    /// 极光三色停靠点：全部走明亮粉系固定色，禁用会随暗色模式变黑的语义色
    var colorStops: [Color] = [
        Color(red: 1.0, green: 0.78, blue: 0.96),
        Color.cc.primary,
        Color(red: 1.0, green: 0.55, blue: 0.90),
    ]

    public init(
        visible: Bool,
        amplitude: Float = 0.7,
        blend: Float = 0.55,
        speed: Float = 1.6
    ) {
        self.visible = visible
        self.amplitude = amplitude
        self.blend = blend
        self.speed = speed
    }

    /// 相位累计器：已播放总时长（暂停时冻结于此值）
    @State private var playedTime: TimeInterval = 0
    /// 本次点亮的续播起点
    @State private var resumedAt = Date.now

    public static func == (lhs: CCAuroraLayer, rhs: CCAuroraLayer) -> Bool {
        lhs.visible == rhs.visible
    }

    public var body: some View {
        GeometryReader { geo in
            // 不可见时暂停时间轴：shader 帧更新彻底归零，不给主线程留后台开销
            TimelineView(.animation(minimumInterval: nil, paused: !visible)) { timeline in
                // 相位 = 冻结累计 + 本次续播增量：暂停/恢复之间时间轴严格连续，
                // 挂钟在暂停期间攒下的跨度永远进不了 shader
                let live = visible ? max(0, resumedAt.distance(to: timeline.date)) : 0
                let elapsed = Float(playedTime + live) * speed

                Rectangle()
                    .visualEffect { content, proxy in
                        let a = colorStops[0].toRGB()
                        let b = colorStops[1].toRGB()
                        let c = colorStops[2].toRGB()
                        let shader = CCShaders.aurora(
                            .float(elapsed),
                            .float(amplitude),
                            .float3(a.x, a.y, a.z),
                            .float3(b.x, b.y, b.z),
                            .float3(c.x, c.y, c.z),
                            .float2(Float(proxy.size.width), Float(proxy.size.height)),
                            .float(blend)
                        )
                        return content.colorEffect(shader)
                    }
            }
            // 时间 uniform 禁入任何环境动画事务：一旦被隐式动画插值，
            // 暂停攒下的时间差会被当作动画量在淡入窗口内「补播」——就是那阵疯狂加速
            .transaction { $0.animation = nil }
            // 占屏底部约一半，钉底
            .frame(width: geo.size.width, height: geo.size.height * 0.52)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .allowsHitTesting(false)
        .opacity(visible ? 1 : 0)
        // 淡入必须 1.2s 匀滑升到 1，禁止骤亮；淡出稍缓
        .animation(.easeInOut(duration: visible ? 1.2 : 0.8), value: visible)
        .ignoresSafeArea()
        .onChange(of: visible) { _, isVisible in
            if isVisible {
                // 从冻结相位无缝续播
                resumedAt = .now
            } else {
                // 冻结当前相位，等待下次点亮
                playedTime += resumedAt.distance(to: .now)
            }
        }
    }
}

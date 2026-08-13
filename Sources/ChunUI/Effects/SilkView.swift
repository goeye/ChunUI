//
//  SilkView.swift
//  YUI
//
//  丝绸效果视图 - 从 React Three.js Silk 移植
//

/**
 * [INPUT]: speed, scale, color, noiseIntensity, rotation 参数
 * [OUTPUT]: 丝绸流动效果视图
 * [POS]: 设计系统/Effects - 用于菜系卡片背景
 *
 * [PROTOCOL]:
 * 1. iOS 17+ 使用 Metal shader
 * 2. iOS 16 降级为静态渐变
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Silk 丝绸效果
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct SilkView: View {
    /// 动画速度 (默认 5)
    var speed: Float = 5.0

    /// 噪声缩放 (默认 1)
    var scale: Float = 1.0


    /// 基础颜色 (默认 #7B7481)
    var color: Color = Color(hex: "7B7481")

    /// 噪声强度 (默认 1.5)
    var noiseIntensity: Float = 1.5

    /// 旋转角度 (默认 0)
    var rotation: Float = 0.0

    let now = Date.now

    public init(speed: Float = 5.0, scale: Float = 1.0, color: Color = Color(hex: "7B7481"), noiseIntensity: Float = 1.5, rotation: Float = 0.0) {
        self.speed = speed
        self.scale = scale
        self.color = color
        self.noiseIntensity = noiseIntensity
        self.rotation = rotation
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(now.distance(to: timeline.date))

            Rectangle()
                .visualEffect { content, proxy in
                    let rgb = color.toRGB()

                    let shader = CCShaders.silk(
                        .float(elapsedTime),
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(speed),
                        .float(scale),
                        .float(noiseIntensity),
                        .float(rotation),
                        .float3(rgb.x, rgb.y, rgb.z)
                    )

                    return content.colorEffect(shader)
                }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#Preview("Silk - Default") {
    SilkView(
        speed: 5,
        scale: 1,
        color: Color(hex: "7B7481"),
        noiseIntensity: 1.5,
        rotation: 0
    )
    .frame(width: 300, height: 200)
    .clipShape(RoundedRectangle(cornerRadius: 20))
}

#Preview("Silk - Brown Leather") {
    SilkView(
        speed: 3,
        scale: 1.5,
        color: Color.cc.primary,
        noiseIntensity: 1.2,
        rotation: -15
    )
    .frame(width: 300, height: 200)
    .clipShape(RoundedRectangle(cornerRadius: 20))
}

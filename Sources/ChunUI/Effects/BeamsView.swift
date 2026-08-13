//
//  BeamsView.swift
//  YUI
//
//  光束效果视图 - 从 React Three.js Beams 移植
//

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Beams 光束效果
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct BeamsView: View {
    /// 光束宽度 (默认 2)
    var beamWidth: Float = 2.0

    /// 光束数量 (默认 12)
    var beamCount: Float = 12.0


    /// 动画速度 (默认 2)
    var speed: Float = 2.0

    /// 噪声缩放 (默认 0.2)
    var scale: Float = 0.2

    /// 噪声强度 (默认 1.75)
    var noiseIntensity: Float = 1.75

    /// 旋转角度 (默认 0，可设置如 -30 表示斜向)
    var rotation: Float = 0.0

    /// 光照颜色 (默认白色)
    var lightColor: Color = .white

    let now = Date.now

    public init(beamWidth: Float = 2.0, beamCount: Float = 12.0, speed: Float = 2.0, scale: Float = 0.2, noiseIntensity: Float = 1.75, rotation: Float = 0.0, lightColor: Color = .white) {
        self.scale = scale
        self.noiseIntensity = noiseIntensity
        self.beamWidth = beamWidth
        self.beamCount = beamCount
        self.speed = speed
        self.rotation = rotation
        self.lightColor = lightColor
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(now.distance(to: timeline.date))

            Rectangle()
                .visualEffect { content, proxy in
                    let lightRGB = lightColor.toRGB()

                    let shader = CCShaders.beams(
                        .float(elapsedTime),
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(beamWidth * 0.05),  // 缩放到合理范围
                        .float(beamCount),
                        .float(speed),
                        .float(scale),
                        .float(noiseIntensity),
                        .float(rotation),
                        .float3(lightRGB.x, lightRGB.y, lightRGB.z)
                    )

                    return content.colorEffect(shader)
                }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#Preview("Beams - Original") {
    // 原始参数: beamWidth=2, beamNumber=12, speed=2, noiseIntensity=1.75, scale=0.2, rotation=0
    BeamsView(
        beamWidth: 2,
        beamCount: 12,
        speed: 2,
        scale: 0.2,
        noiseIntensity: 1.75,
        rotation: 0,
        lightColor: .white
    )
    .frame(width: 300, height: 200)
    .background(Color.cc.darkCard)
    .clipShape(RoundedRectangle(cornerRadius: 20))
}

#Preview("Beams - Diagonal") {
    BeamsView(
        beamWidth: 2,
        beamCount: 12,
        speed: 2,
        scale: 0.2,
        noiseIntensity: 1.75,
        rotation: -30,
        lightColor: .white
    )
    .frame(width: 300, height: 200)
    .background(Color.cc.darkCard)
    .clipShape(RoundedRectangle(cornerRadius: 20))
}

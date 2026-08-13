//
//  ColorBendsView.swift
//  YUI
//
//  流动光效视图 - 从 React Three.js 移植
//

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ColorBends 流动光效
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct ColorBendsView: View {
    var speed: Float = 0.15
    var scale: Float = 1.0
    var frequency: Float = 1.0
    var warpStrength: Float = 0.8
    var color1: Color = .cc.secondary
    var color2: Color = .cc.primary

    public init(speed: Float = 0.15, color1: Color = .cc.secondary, color2: Color = .cc.primary) {
        self.speed = speed
        self.color1 = color1
        self.color2 = color2
    }
    var color3: Color = .cc.background

    let now = Date.now

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(now.distance(to: timeline.date)) * speed

            Rectangle()
                .visualEffect { content, proxy in
                    let rgb1 = color1.toRGB()
                    let rgb2 = color2.toRGB()
                    let rgb3 = color3.toRGB()

                    let shader = CCShaders.colorBends(
                        .float(elapsedTime),
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(scale),
                        .float(frequency),
                        .float(warpStrength),
                        .float3(rgb1.x, rgb1.y, rgb1.z),
                        .float3(rgb2.x, rgb2.y, rgb2.z),
                        .float3(rgb3.x, rgb3.y, rgb3.z)
                    )

                    return content.colorEffect(shader)
                }
        }
    }
}

#Preview {
    ColorBendsView()
        .frame(width: 300, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
}

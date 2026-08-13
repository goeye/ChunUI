//
//  CCShaderBackground.swift
//  YUI
//
//  Created by 赵纯想 on 2024/03/21.
//

import SwiftUI

// MARK: - AuroraBackground修饰符

/// Aurora背景效果的视图修饰符
public struct AurorabackGround: View {
    var amplitude: Float = 0.3
    var blend: Float = 0.3
    var speed: Float = 1.2
    var colorStops: [Color] = [Color.cc.background, Color.cc.muted, Color.cc.accent]
    let now = Date.now
    
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(now.distance(to: timeline.date)) * speed
            
            Rectangle()
                .visualEffect { content, proxy in
                    // 创建着色器
                    let rgb1 = colorStops[0].toRGB()
                    let rgb2 = colorStops[1].toRGB()
                    let rgb3 = colorStops[2].toRGB()

                    let shader = CCShaders.aurora(
                        .float(elapsedTime), // 使用timeline提供的时间
                        .float(amplitude),
                        .float3(rgb1.x, rgb1.y, rgb1.z),
                        .float3(rgb2.x, rgb2.y, rgb2.z),
                        .float3(rgb3.x, rgb3.y, rgb3.z),
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(blend)
                    )

                    return content.colorEffect(shader)
                }
                .ignoresSafeArea()
        }
    }
}

#Preview {
    AurorabackGround()
}

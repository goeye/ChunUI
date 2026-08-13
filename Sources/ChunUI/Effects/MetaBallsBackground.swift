//
//  MetaBallsBackground.swift
//  YUI
//
//  Created by 赵纯想 on 2024/05/19.
//

import SwiftUI

/// MetaBalls液态球背景效果的视图修饰符
public struct MetaBallsBackground: View {
    // 配置参数
    var color: Color = Color.cc.background
    var speed: Float = 0.7
    var animationSize: Float = 30
    var ballCount: Float = 8
    var clumpFactor: Float = 0.8
    var enableTransparency: Bool = false
    
    public init(color: Color = Color.cc.background, speed: Float = 0.7, animationSize: Float = 30, ballCount: Float = 8, clumpFactor: Float = 0.8, enableTransparency: Bool = false) {
        self.animationSize = animationSize
        self.clumpFactor = clumpFactor
        self.color = color
        self.speed = speed
        self.ballCount = ballCount
        self.enableTransparency = enableTransparency
    }

    // 时间控制
    let now = Date.now
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(now.distance(to: timeline.date)) * speed

            Rectangle()
                .visualEffect { content, proxy in
                    let rgb = color.toRGB()

                    let shader = CCShaders.metaBalls(
                        .float(elapsedTime),
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float3(rgb.x, rgb.y, rgb.z),
                        .float(animationSize),
                        .float(ballCount),
                        .float(clumpFactor)
                    )

                    return content.colorEffect(shader)
                }
                .ignoresSafeArea()
        }
    }
}

// 可使用ViewModifier方式
extension View {
    func metaBallsBackground(
        color: Color = Color.cc.background,
        speed: Float = 0.3,
        animationSize: Float = 30,
        ballCount: Float = 15,
        clumpFactor: Float = 1.0,
        enableTransparency: Bool = false
    ) -> some View {
        ZStack {
            MetaBallsBackground(
                color: color,
                speed: speed,
                animationSize: animationSize,
                ballCount: ballCount,
                clumpFactor: clumpFactor,
                enableTransparency: enableTransparency
            )
            self
        }
    }
}

// 预览
#Preview {
    VStack {
        Text("MetaBalls效果")
            .ccText(font: .cc.title2Bold, color: .cc.background)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
    }
    .metaBallsBackground(
        color: Color.cc.chartProtein,
        speed: 0.7,
        animationSize: 56,
        ballCount: 12,
        clumpFactor: 0.8
    )
} 

//
//  MetaBallsDemo.swift
//  YUI
//
//  Created by 赵纯想 on 2024/05/19.
//

import SwiftUI

public struct MetaBallsDemo: View {
    @State private var speed: Double = 0.5
    @State private var animationSize: Double = 40
    @State private var ballCount: Double = 20
    @State private var clumpFactor: Double = 0.8
    @State private var color: Color = Color.cc.info
    @State private var colors: [Color] = [
        Color.cc.info,
        Color.cc.chartProtein,
        Color.cc.chartCarbs,
        Color.cc.chartFat
    ]
    @State private var selectedColorIndex = 0

    public var body: some View {
        VStack {
            Text("MetaBalls效果演示")
                .ccText(font: .cc.title1Bold, color: .cc.background)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            
            Spacer()
            
            // 控制面板
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("速度: \(speed, specifier: "%.1f")")
                        .ccText(font: .cc.callout, color: .cc.background)
                    Slider(value: $speed, in: 0.1...2.0)
                        .tint(Color.cc.background)
                }

                VStack(alignment: .leading) {
                    Text("动画大小: \(Int(animationSize))")
                        .ccText(font: .cc.callout, color: .cc.background)
                    Slider(value: $animationSize, in: 10...100)
                        .tint(Color.cc.background)
                }

                VStack(alignment: .leading) {
                    Text("球体数量: \(Int(ballCount))")
                        .ccText(font: .cc.callout, color: .cc.background)
                    Slider(value: $ballCount, in: 5...40)
                        .tint(Color.cc.background)
                }

                VStack(alignment: .leading) {
                    Text("聚集因子: \(clumpFactor, specifier: "%.1f")")
                        .ccText(font: .cc.callout, color: .cc.background)
                    Slider(value: $clumpFactor, in: 0.1...2.0)
                        .tint(Color.cc.background)
                }

                HStack {
                    Text("颜色:")
                        .ccText(font: .cc.callout, color: .cc.background)
                    
                    ForEach(0..<colors.count, id: \.self) { index in
                        Circle()
                            .fill(colors[index])
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(selectedColorIndex == index ? Color.cc.background : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedColorIndex = index
                                color = colors[index]
                            }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding()
        }
        .metaBallsBackground(
            color: color,
            speed: Float(speed),
            animationSize: Float(animationSize),
            ballCount: Float(ballCount),
            clumpFactor: Float(clumpFactor)
        )
    }
}

#Preview {
    MetaBallsDemo()
} 

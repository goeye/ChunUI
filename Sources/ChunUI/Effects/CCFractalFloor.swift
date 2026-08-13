//
//  CCFractalFloor.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Shader/FractalTextures.metal 的九种分形点阵（Julia/Newton³/Mandelbrot/Burning Ship/Tricorn/Celtic/Phoenix/Multibrot³/Newton⁴）与 Color.cc.primary
 * [OUTPUT]: 对外提供 CCFractalFloor（ASCII 点阵分形 24fps 演化，kind 选分形族，edge 控制贴底向上渐隐 / 贴顶向下渐隐，全族恒主题色）
 * [POS]: DesignSystem/Effects 的品牌质感地板——关于页贴底、登录页倒置贴顶，同一 halftone 语言
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

public struct CCFractalFloor: View {
    public enum Edge {
        case top        // 贴顶，向下渐隐（登录页）
        case bottom     // 贴底，向上渐隐（关于页）
    }

    /// 分形族（九种，页页不同）
    public enum Kind {
        case julia, newton3, mandelbrot, burningShip, tricorn, celtic, phoenix, multibrot3, newton4
    }

    var edge: Edge = .bottom
    var height: CGFloat = 300
    var kind: Kind = .mandelbrot

    public init(edge: Edge = .bottom, height: CGFloat = 300, kind: Kind = .mandelbrot) {
        self.edge = edge
        self.height = height
        self.kind = kind
    }

    @State private var start = Date.now

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 24.0)) { timeline in
            surface(time: Float(start.distance(to: timeline.date)))
        }
        .frame(height: height)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.7), location: 0.45),
                    .init(color: .black, location: 1.0),
                ],
                startPoint: edge == .bottom ? .top : .bottom,
                endPoint: edge == .bottom ? .bottom : .top
            )
        }
    }

    private func surface(time: Float) -> some View {
        let tint = Color.cc.primary.toRGB()
        let kind = self.kind
        return Rectangle()
            .visualEffect { content, proxy in
                let size = SIMD2<Float>(Float(proxy.size.width), Float(proxy.size.height))
                let shader: Shader = switch kind {
                case .julia: CCShaders.fractalJulia(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                case .newton3: CCShaders.fractalNewton(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                case .mandelbrot: CCShaders.fractalMandelbrot(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                case .burningShip: CCShaders.fractalBurningShip(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                case .tricorn: CCShaders.fractalTricorn(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                case .celtic: CCShaders.fractalCeltic(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                case .phoenix: CCShaders.fractalPhoenix(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                case .multibrot3: CCShaders.fractalMultibrot3(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                case .newton4: CCShaders.fractalNewton4(.float2(size.x, size.y), .float(time), .float3(tint.x, tint.y, tint.z))
                }
                return content.colorEffect(shader)
            }
    }
}

//
//  CCRainbowBar.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Color.cc 灰阶令牌与 Color.mix（灰底 = foreground 12% 混 background）、TimelineView(.animation) 帧驱动
 * [OUTPUT]: 对外提供 CCRainbowBar 彩虹进度条（Laper CountdownProgressEffect 1:1 移植：潘通式精选 12 色 160pt 周期主彩带 3.2s 滚动 + 纯白高光纱 120pt 周期 5.6s 异速交织 + 顶部薄白纱提亮 + 右缘投影，填充层自带圆角从左生长非硬切）；相位由 TimelineView 时刻直接推导——无状态无 repeatForever，任何父级动画事务都杀不死滚动
 * [POS]: DesignSystem/Compents 的进度条质感原语，被 OnboardingChrome/GeneratingPage 消费；零滤镜零混色纲领——鲜活靠精选色谱本身
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

public struct CCRainbowBar: View {
    /// 0...1 进度
    var progress: Double
    var height: CGFloat = 12

    public init(progress: Double, height: CGFloat = 12) {
        self.progress = progress
        self.height = height
    }

    /// 主题化谱带覆写：宿主可整组换色（如品牌同轴单色系彩带），nil = 内置 12 色
    nonisolated(unsafe) public static var spectrumOverride: [Color]?

    private var activeSpectrum: [Color] { Self.spectrumOverride ?? Self.spectrum }

    /// 潘通式精选 12 色（Laper 口径：每族最亮档、按色相升序围环、已踢暗紫防浊）
    private static let spectrum: [Color] = [
        Color(hex: "E53935"), Color(hex: "E65100"), Color(hex: "F4A300"),
        Color(hex: "FFD700"), Color(hex: "388E3C"), Color(hex: "3d8b68"),
        Color(hex: "00A78E"), Color(hex: "0277BD"), Color(hex: "1976D2"),
        Color(hex: "3F51B5"), Color(hex: "5E35B1"), Color(hex: "D81B60"),
    ]

    private let ribbonPeriod: CGFloat = 160
    private let sheenPeriod: CGFloat = 120

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            TimelineView(.animation) { timeline in
                // 相位直接由时刻推导（周期取模）：无状态、无 repeatForever，父级动画事务免疫
                let now = timeline.date.timeIntervalSinceReferenceDate
                let ribbonPhase = CGFloat(now.truncatingRemainder(dividingBy: 3.2) / 3.2)
                let sheenPhase = CGFloat(now.truncatingRemainder(dividingBy: 5.6) / 5.6)

                ZStack(alignment: .leading) {
                    // ① 灰底铺底（剩余区）· foreground 12% 混色
                    Capsule()
                        .fill(Color.cc.foreground.mix(with: Color.cc.background, amount: 0.88))

                    // ② 彩虹填充层 · 自带圆角从左生长（右缘圆角非硬切）
                    ZStack(alignment: .leading) {
                        ribbon(width: width, phase: ribbonPhase)
                        sheen(width: width, phase: sheenPhase)
                        // 顶部薄白纱 · 高光质感（只盖彩虹区）
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.25), location: 0),
                                .init(color: .white.opacity(0.06), location: 0.55),
                                .init(color: .white.opacity(0), location: 1),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    }
                    .frame(width: max(height, width * progress))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 3, x: 2, y: 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.9), value: progress)
                }
            }
        }
        .frame(height: height)
    }

    /// 主彩带：12 色 160pt 周期平铺，相位平移无缝回相（3.2s/周期 ≈ 50pt/s）
    private func ribbon(width: CGFloat, phase: CGFloat) -> some View {
        let tiles = max(1, Int(ceil(width / ribbonPeriod)) + 1)
        return LinearGradient(
            stops: Self.tiledStops(colors: activeSpectrum, tiles: tiles),
            startPoint: .leading, endPoint: .trailing
        )
        .frame(width: CGFloat(tiles) * ribbonPeriod)
        .offset(x: -ribbonPeriod * phase)
    }

    /// 高光纱：纯白透明带异速滚动——只提亮不混色相，相位差即交织光泽
    private func sheen(width: CGFloat, phase: CGFloat) -> some View {
        let tiles = max(1, Int(ceil(width / sheenPeriod)) + 1)
        let band: [(Double, Double)] = [(0, 0), (0.05, 38 / 120), (0.22, 60 / 120), (0.05, 82 / 120), (0, 1)]
        var stops: [Gradient.Stop] = []
        for tile in 0 ..< tiles {
            for (opacity, position) in band {
                stops.append(.init(
                    color: .white.opacity(opacity),
                    location: (Double(tile) + position) / Double(tiles)
                ))
            }
        }
        return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
            .frame(width: CGFloat(tiles) * sheenPeriod)
            .offset(x: -sheenPeriod * phase)
    }

    /// 12 色按 tile 平铺为渐变 stops（末位回猩红闭环，邻位色相近邻恒高饱和不过灰区）
    private static func tiledStops(colors: [Color], tiles: Int) -> [Gradient.Stop] {
        var stops: [Gradient.Stop] = []
        let count = Double(colors.count)
        for tile in 0 ..< tiles {
            for (i, color) in colors.enumerated() {
                stops.append(.init(color: color, location: (Double(tile) + Double(i) / count) / Double(tiles)))
            }
        }
        stops.append(.init(color: colors[0], location: 1))
        return stops
    }
}

#Preview {
    VStack(spacing: 24) {
        CCRainbowBar(progress: 0.3)
        CCRainbowBar(progress: 0.7)
        CCRainbowBar(progress: 1)
    }
    .padding(24)
    .background(Color.cc.background)
}

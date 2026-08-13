//
//  CCSweepLight.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Shader/GlimmSweep.metal 的 glimmSweep 片元、UIWindowScene 顶层窗口、SwiftUI TimelineView/colorEffect
 * [OUTPUT]: 对外提供 CCSweepLight.fire() 一次性全屏扫光（Laper glimm 装配 1:1：sweep 620ms easeOutQuart + outro 260ms 渐隐、peakAlpha 0.88、hueShift 每发随机 0..0.4），穿透触摸零交互
 * [POS]: DesignSystem/Effects 的转场扫光协调器，被 OnboardingFlowCoordinator 步进消费；与 CCToastWindow 同属顶层覆盖窗范式
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

@MainActor
public enum CCSweepLight {
    /// 主题色化扫光：置为宿主色（宜用明亮变体，如兰花紫），nil = 原版 citrus 虹彩
    nonisolated(unsafe) public static var tint: Color?

    private static var window: UIWindow?

    /// 发射一次全屏扫光（进行中重入直接忽略，扫完自动拆窗）
    public static func fire() {
        guard window == nil else { return }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else { return }

        let overlay = UIWindow(windowScene: scene)
        overlay.windowLevel = .alert + 2
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = false

        let host = UIHostingController(rootView: SweepOverlay {
            Task { @MainActor in
                window?.isHidden = true
                window = nil
            }
        })
        host.view.backgroundColor = .clear
        overlay.rootViewController = host
        overlay.isHidden = false
        window = overlay
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SweepOverlay（时间驱动：620ms easeOutQuart 扫过 + 260ms 渐隐收尾）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct SweepOverlay: View {
    var onDone: () -> Void

    @State private var start = Date()
    private let hueShift = Double.random(in: 0 ... 0.4)
    private let sweepDuration = 0.62
    private let outroDuration = 0.26
    private let peakAlpha = 0.88

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(start)
                let raw = min(1, elapsed / sweepDuration)
                let progress = 1 - pow(1 - raw, 4)   // easeOutQuart
                let alpha = elapsed <= sweepDuration
                    ? peakAlpha
                    : max(0, peakAlpha * (1 - (elapsed - sweepDuration) / outroDuration))

                let tintRGB = CCSweepLight.tint?.toRGB() ?? SIMD3<Float>(0, 0, 0)
                Rectangle()
                    .fill(Color.white)
                    .colorEffect(CCShaders.glimmSweep(
                        .float2(Float(geo.size.width), Float(geo.size.height)),
                        .float(Float(elapsed)),
                        .float(Float(progress)),
                        .float(Float(alpha)),
                        .float(Float(hueShift)),
                        .float3(tintRGB.x, tintRGB.y, tintRGB.z),
                        .float(CCSweepLight.tint == nil ? 0 : 0.85)
                    ))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task {
            try? await Task.sleep(nanoseconds: 950_000_000)
            onDone()
        }
    }
}

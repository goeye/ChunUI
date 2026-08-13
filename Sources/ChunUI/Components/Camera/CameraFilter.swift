//
//  CameraFilter.swift
//  YUI
//
//  [INPUT]: CIImage 原始帧
//  [OUTPUT]: 应用滤镜后的 CIImage
//  [POS]: 美食摄影滤镜定义 - 针对食物拍摄优化的色彩处理
//
//  [PROTOCOL]:
//  1. 每个滤镜针对特定食物类型优化
//  2. apply() 使用 CIFilter 链式处理
//  3. 暗角/颗粒等叠加效果在 FilmSimulationOverlay 中处理
//

import CoreImage
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 美食摄影滤镜
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CameraFilter: String, CaseIterable {
    /// 标准模式 - 无处理
    case none

    /// 暖食 - 暖色调 + 饱和度提升 (适合热菜、烤肉、火锅)
    case vividWarm

    /// 清新 - 明亮清透 (适合沙拉、寿司、甜点)
    case fresh

    /// 美馔 - 高对比 + 金色高光 (餐厅级质感)
    case gourmet

    /// 复古 - 暖棕调 + 柔和对比 (咖啡、烘焙、手作)
    case rustic

    /// 黑白 - 经典单色 (高级料理、摆盘艺术)
    case mono

    // ━━━ 显示名称 ━━━
    var displayName: String {
        switch self {
        case .none: return "STANDARD"
        case .vividWarm: return "VIVID WARM"
        case .fresh: return "FRESH"
        case .gourmet: return "GOURMET"
        case .rustic: return "RUSTIC"
        case .mono: return "MONO"
        }
    }

    var shortName: String {
        switch self {
        case .none: return "STD"
        case .vividWarm: return "VIV"
        case .fresh: return "FRS"
        case .gourmet: return "GOU"
        case .rustic: return "RUS"
        case .mono: return "B&W"
        }
    }

    // ━━━ 暗角强度 ━━━
    var vignetteIntensity: Double {
        switch self {
        case .none: return 0.2
        case .vividWarm: return 0.25
        case .fresh: return 0.15
        case .gourmet: return 0.35
        case .rustic: return 0.4
        case .mono: return 0.45
        }
    }

    // ━━━ 覆盖层色调 ━━━
    var overlayColor: Color {
        switch self {
        case .vividWarm: return Color(hex: "ff6b00").opacity(0.06)
        case .fresh: return Color(hex: "00d4ff").opacity(0.03)
        case .gourmet: return Color(hex: "ffd700").opacity(0.05)
        case .rustic: return Color(hex: "8b4513").opacity(0.04)
        default: return .clear
        }
    }

    var overlayOpacity: Double {
        switch self {
        case .vividWarm: return 0.08
        case .fresh: return 0.05
        case .gourmet: return 0.1
        case .rustic: return 0.12
        default: return 0
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - CIFilter 应用
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func apply(to image: CIImage, context: CIContext) -> CIImage {
        switch self {
        case .none:
            return image

        case .vividWarm:
            return applyVividWarm(to: image)

        case .fresh:
            return applyFresh(to: image)

        case .gourmet:
            return applyGourmet(to: image)

        case .rustic:
            return applyRustic(to: image)

        case .mono:
            return applyMono(to: image)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 暖食滤镜 (Vivid Warm)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 暖色调 + 高饱和度，让热菜看起来更诱人
    private func applyVividWarm(to image: CIImage) -> CIImage {
        var result = image

        // 1. 提升饱和度
        if let vibrance = CIFilter(name: "CIVibrance") {
            vibrance.setValue(result, forKey: kCIInputImageKey)
            vibrance.setValue(0.5, forKey: "inputAmount")
            result = vibrance.outputImage ?? result
        }

        // 2. 暖色调偏移
        if let temperature = CIFilter(name: "CITemperatureAndTint") {
            temperature.setValue(result, forKey: kCIInputImageKey)
            temperature.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temperature.setValue(CIVector(x: 7500, y: 50), forKey: "inputTargetNeutral")
            result = temperature.outputImage ?? result
        }

        // 3. 轻微对比度提升
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(result, forKey: kCIInputImageKey)
            colorControls.setValue(1.05, forKey: kCIInputContrastKey)
            colorControls.setValue(0.02, forKey: kCIInputBrightnessKey)
            result = colorControls.outputImage ?? result
        }

        return result
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 清新滤镜 (Fresh)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 明亮清透，适合展现食材的新鲜感
    private func applyFresh(to image: CIImage) -> CIImage {
        var result = image

        // 1. 提亮 + 轻微降低对比度 (更清透)
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(result, forKey: kCIInputImageKey)
            colorControls.setValue(1.0, forKey: kCIInputSaturationKey)
            colorControls.setValue(0.98, forKey: kCIInputContrastKey)
            colorControls.setValue(0.05, forKey: kCIInputBrightnessKey)
            result = colorControls.outputImage ?? result
        }

        // 2. 轻微冷色调 (更清新)
        if let temperature = CIFilter(name: "CITemperatureAndTint") {
            temperature.setValue(result, forKey: kCIInputImageKey)
            temperature.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temperature.setValue(CIVector(x: 6200, y: -10), forKey: "inputTargetNeutral")
            result = temperature.outputImage ?? result
        }

        // 3. 高光恢复
        if let highlights = CIFilter(name: "CIHighlightShadowAdjust") {
            highlights.setValue(result, forKey: kCIInputImageKey)
            highlights.setValue(0.9, forKey: "inputHighlightAmount")
            highlights.setValue(0.1, forKey: "inputShadowAmount")
            result = highlights.outputImage ?? result
        }

        return result
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 美馔滤镜 (Gourmet)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 高对比 + 金色高光，餐厅级摄影质感
    private func applyGourmet(to image: CIImage) -> CIImage {
        var result = image

        // 1. 高对比度 + 饱和度
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(result, forKey: kCIInputImageKey)
            colorControls.setValue(1.15, forKey: kCIInputSaturationKey)
            colorControls.setValue(1.1, forKey: kCIInputContrastKey)
            result = colorControls.outputImage ?? result
        }

        // 2. 金色暖调
        if let temperature = CIFilter(name: "CITemperatureAndTint") {
            temperature.setValue(result, forKey: kCIInputImageKey)
            temperature.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temperature.setValue(CIVector(x: 7000, y: 30), forKey: "inputTargetNeutral")
            result = temperature.outputImage ?? result
        }

        // 3. 阴影加深 (更立体)
        if let highlights = CIFilter(name: "CIHighlightShadowAdjust") {
            highlights.setValue(result, forKey: kCIInputImageKey)
            highlights.setValue(1.0, forKey: "inputHighlightAmount")
            highlights.setValue(-0.15, forKey: "inputShadowAmount")
            result = highlights.outputImage ?? result
        }

        return result
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 复古滤镜 (Rustic)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 暖棕色调 + 柔和对比，手作烘焙质感
    private func applyRustic(to image: CIImage) -> CIImage {
        var result = image

        // 1. 降低对比度 + 轻微褪色
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(result, forKey: kCIInputImageKey)
            colorControls.setValue(0.9, forKey: kCIInputSaturationKey)
            colorControls.setValue(0.95, forKey: kCIInputContrastKey)
            colorControls.setValue(0.02, forKey: kCIInputBrightnessKey)
            result = colorControls.outputImage ?? result
        }

        // 2. 暖棕色调
        if let temperature = CIFilter(name: "CITemperatureAndTint") {
            temperature.setValue(result, forKey: kCIInputImageKey)
            temperature.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temperature.setValue(CIVector(x: 7800, y: 40), forKey: "inputTargetNeutral")
            result = temperature.outputImage ?? result
        }

        // 3. 褐色调 (Sepia 变体)
        if let sepia = CIFilter(name: "CISepiaTone") {
            sepia.setValue(result, forKey: kCIInputImageKey)
            sepia.setValue(0.15, forKey: kCIInputIntensityKey)
            result = sepia.outputImage ?? result
        }

        return result
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 黑白滤镜 (Mono)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 经典黑白，强调形态与质感
    private func applyMono(to image: CIImage) -> CIImage {
        var result = image

        // 1. 黑白转换
        if let mono = CIFilter(name: "CIPhotoEffectMono") {
            mono.setValue(result, forKey: kCIInputImageKey)
            result = mono.outputImage ?? result
        }

        // 2. 提升对比度
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(result, forKey: kCIInputImageKey)
            colorControls.setValue(1.15, forKey: kCIInputContrastKey)
            result = colorControls.outputImage ?? result
        }

        return result
    }
}

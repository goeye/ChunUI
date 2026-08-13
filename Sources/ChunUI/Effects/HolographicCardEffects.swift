import SwiftUI

// MARK: - 卡牌全息效果修饰符

/// 应用全息卡片效果的修饰符
 
public struct HolographicCardModifier: ViewModifier {
    // 时间动画状态
    let now = Date.now
    
    // 倾斜角度参数
    var tiltX: Float
    var tiltY: Float
    
    // 卡牌等级
    var rarityLevel: String = "C" // 默认为C级
    
    // 调色板颜色数组
    var paletteColors: [Color] = []
    
    public func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(now.distance(to: timeline.date)) * getAnimationSpeed
            
            content
                .visualEffect { content, proxy in
                    // 获取调色板RGB颜色
                    let colorRGBArray = getColorRGBArray()
                    
                    // 应用全息效果
                    let holographicShader = CCShaders.holographicEffect(
                        .float(elapsedTime),
                        .float(tiltX),
                        .float(tiltY),
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(getHolographicIntensity),
                        .float(getPatternScale),
                        .float(getAnimationSpeed),
                        .float3(colorRGBArray[0][0], colorRGBArray[0][1], colorRGBArray[0][2]),
                        .float3(colorRGBArray[1][0], colorRGBArray[1][1], colorRGBArray[1][2]),
                        .float3(colorRGBArray[2][0], colorRGBArray[2][1], colorRGBArray[2][2]),
                        .float3(colorRGBArray[3][0], colorRGBArray[3][1], colorRGBArray[3][2]),
                        .float3(colorRGBArray[4][0], colorRGBArray[4][1], colorRGBArray[4][2]),
                        .float3(colorRGBArray[5][0], colorRGBArray[5][1], colorRGBArray[5][2])
                    )
                    
                    // 应用边缘发光效果
                    let glowShader = CCShaders.cardGlowEffect(
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(elapsedTime),
                        .float(getGlowWidth),
                        .float(getGlowIntensity),
                        .float3(getGlowColor.toRGB().x, getGlowColor.toRGB().y, getGlowColor.toRGB().z)
                    )
                    
                    // 应用宝可梦特有的水平镭射线效果，增强稀有感
                    let holoLinesShader = CCShaders.pokemonHoloLinesEffect(
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(elapsedTime),
                        .float(tiltX),
                        .float(tiltY),
                        .float(getHoloIntensityForRarity),
                        .float3(colorRGBArray[0][0], colorRGBArray[0][1], colorRGBArray[0][2]),
                        .float3(colorRGBArray[1][0], colorRGBArray[1][1], colorRGBArray[1][2]),
                        .float3(colorRGBArray[2][0], colorRGBArray[2][1], colorRGBArray[2][2]),
                        .float3(colorRGBArray[3][0], colorRGBArray[3][1], colorRGBArray[3][2]),
                        .float3(colorRGBArray[4][0], colorRGBArray[4][1], colorRGBArray[4][2]),
                        .float3(colorRGBArray[5][0], colorRGBArray[5][1], colorRGBArray[5][2])
                    )
                    
                    return content
                        .colorEffect(holographicShader)
                        .colorEffect(glowShader)
                        .colorEffect(holoLinesShader)
                }
        }
    }
    
    // 获取RGB颜色数组，如果palette为空则使用默认颜色
    nonisolated private func getColorRGBArray() -> [SIMD3<Float>] {
        // 默认颜色 (使用设计系统颜色)
        let defaultColors: [Color] = [
            Color.cc.secondary,      // 金色调
            Color.cc.info,           // 蓝色调
            Color.cc.chartProtein,   // 粉红色调
            Color.cc.primary,        // 紫色调
            Color.cc.chartCarbs,     // 青绿色调
            Color.cc.chartFat        // 橙色调
        ]

        // 如果没有提供调色板颜色，使用默认颜色
        let colorsToUse = paletteColors.isEmpty || paletteColors.count < 6 ? defaultColors : paletteColors

        // 转换为SIMD3<Float>数组
        return colorsToUse.map { color in
            let rgb = color.toRGB()
            return SIMD3<Float>(rgb.x, rgb.y, rgb.z)
        }
    }
    
    // 根据稀有度设置光效强度
    nonisolated var getHoloIntensityForRarity: Float {
        switch rarityLevel {
        case "SSR": return 0.95
        case "SR": return 0.85
        case "S": return 0.75
        case "A": return 0.6
        case "B": return 0.45
        case "C": return 0.3
        default: return 0.2
        }
    }
    
    // 根据稀有度设置全息效果强度
    nonisolated var getHolographicIntensity: Float {
        switch rarityLevel {
        case "SSR": return 0.7
        case "SR": return 0.65
        case "S": return 0.6
        case "A": return 0.5
        case "B": return 0.4
        case "C": return 0.3
        default: return 0.2
        }
    }
    
    // 根据稀有度设置纹理比例
    nonisolated var getPatternScale: Float {
        switch rarityLevel {
        case "SSR": return 1.8
        case "SR": return 1.7
        case "S": return 1.6
        case "A": return 1.5
        case "B": return 1.4
        case "C": return 1.3
        default: return 1.2
        }
    }
    
    // 根据稀有度设置动画速度
    nonisolated var getAnimationSpeed: Float {
        switch rarityLevel {
        case "SSR": return 1.2
        case "SR": return 1.1
        case "S": return 1.0
        case "A": return 0.9
        case "B": return 0.8
        case "C": return 0.7
        default: return 0.6
        }
    }
    
    // 根据稀有度设置发光宽度
    nonisolated var getGlowWidth: Float {
        switch rarityLevel {
        case "SSR": return 0.16
        case "SR": return 0.15
        case "S": return 0.14
        case "A": return 0.13
        case "B": return 0.12
        case "C": return 0.11
        default: return 0.1
        }
    }
    
    // 根据稀有度设置发光强度
    nonisolated var getGlowIntensity: Float {
        switch rarityLevel {
        case "SSR": return 0.7
        case "SR": return 0.65
        case "S": return 0.6
        case "A": return 0.5
        case "B": return 0.4
        case "C": return 0.3
        default: return 0.2
        }
    }
    
    // 根据稀有度设置发光颜色
    nonisolated var getGlowColor: Color {
        switch rarityLevel {
        case "SSR": return Color.cc.primary
        case "SR": return Color.cc.info
        case "S": return Color.cc.info
        case "A": return Color.cc.chartCarbs
        case "B": return Color.cc.secondary
        case "C": return Color.cc.muted
        default: return Color.cc.mutedForeground
        }
    }
}

// MARK: - 卡牌图片镭射纹理效果

/// 为卡牌图片添加镭射纹理效果
 
public struct HolographicImageModifier: ViewModifier {
    let now = Date.now
    var rarityLevel: String = "C"
    
    // 调色板颜色数组
    var paletteColors: [Color] = []
    
    public func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(now.distance(to: timeline.date)) * getAnimationSpeed
            
            content
                .visualEffect { content, proxy in
                    // 获取调色板RGB颜色
                    let colorRGBArray = getColorRGBArray()
                    
                    let textureShader = CCShaders.holographicTexture(
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(elapsedTime),
                        .float(getPatternScale),
                        .float(getAnimationSpeed),
                        .float(getIntensity),
                        .float3(colorRGBArray[0][0], colorRGBArray[0][1], colorRGBArray[0][2]),
                        .float3(colorRGBArray[1][0], colorRGBArray[1][1], colorRGBArray[1][2]),
                        .float3(colorRGBArray[2][0], colorRGBArray[2][1], colorRGBArray[2][2]),
                        .float3(colorRGBArray[3][0], colorRGBArray[3][1], colorRGBArray[3][2]),
                        .float3(colorRGBArray[4][0], colorRGBArray[4][1], colorRGBArray[4][2]),
                        .float3(colorRGBArray[5][0], colorRGBArray[5][1], colorRGBArray[5][2])
                    )
                    
                    return content.colorEffect(textureShader)
                }
        }
    }
    
    // 获取RGB颜色数组，如果palette为空则使用默认颜色
    nonisolated private func getColorRGBArray() -> [SIMD3<Float>] {
        // 默认颜色 (使用设计系统颜色)
        let defaultColors: [Color] = [
            Color.cc.secondary,      // 金色调
            Color.cc.info,           // 蓝色调
            Color.cc.chartProtein,   // 粉红色调
            Color.cc.primary,        // 紫色调
            Color.cc.chartCarbs,     // 青绿色调
            Color.cc.chartFat        // 橙色调
        ]

        // 如果没有提供调色板颜色，使用默认颜色
        let colorsToUse = paletteColors.isEmpty || paletteColors.count < 6 ? defaultColors : paletteColors

        // 转换为SIMD3<Float>数组
        return colorsToUse.map { color in
            let rgb = color.toRGB()
            return SIMD3<Float>(rgb.x, rgb.y, rgb.z)
        }
    }
    
    // 根据稀有度设置纹理强度
    nonisolated var getIntensity: Float {
        switch rarityLevel {
        case "SSR": return 0.5
        case "SR": return 0.45
        case "S": return 0.4
        case "A": return 0.35
        case "B": return 0.3
        case "C": return 0.25
        default: return 0.2
        }
    }
    
    // 根据稀有度设置纹理比例
    nonisolated var getPatternScale: Float {
        switch rarityLevel {
        case "SSR": return 2.5
        case "SR": return 2.4
        case "S": return 2.3
        case "A": return 2.2
        case "B": return 2.1
        case "C": return 2.0
        default: return 1.8
        }
    }
    
    // 根据稀有度设置动画速度
    nonisolated var getAnimationSpeed: Float {
        switch rarityLevel {
        case "SSR": return 0.7
        case "SR": return 0.65
        case "S": return 0.6
        case "A": return 0.55
        case "B": return 0.5
        case "C": return 0.45
        default: return 0.4
        }
    }
}



// MARK: - View扩展

extension View {
    /// 添加全息卡片效果
    public func holographicCard(tiltX: Float, tiltY: Float, rarity: String = "C", paletteColors: [Color] = []) -> some View {
        self.modifier(HolographicCardModifier(tiltX: tiltX, tiltY: tiltY, rarityLevel: rarity, paletteColors: paletteColors))
    }

    /// 添加全息图片效果
    public func holographicImage(rarity: String = "C", paletteColors: [Color] = []) -> some View {
        self.modifier(HolographicImageModifier(rarityLevel: rarity, paletteColors: paletteColors))
    }
    
}

// MARK: - 3D倾斜跟踪视图
/// 跟踪设备倾斜并应用3D效果的容器视图
public struct TiltTrackingView<Content: View>: View {
    @Binding private var tiltX: CGFloat
    @Binding private var tiltY: CGFloat
    @State private var isDragging: Bool = false
    @State private var isPressed: Bool = false
    
    private let content: Content
    private let tiltSensitivity: CGFloat
    private let maxTiltAngle: CGFloat
    private let pressedScale: CGFloat
    
    public init(tiltSensitivity: CGFloat = 0.3, 
         maxTiltAngle: CGFloat = 15.0, 
         pressedScale: CGFloat = 1.03,
         tiltX : Binding<CGFloat>,
         tiltY: Binding<CGFloat>, 
         @ViewBuilder content: () -> Content) {
        self._tiltX = tiltX
        self._tiltY = tiltY
        self.content = content()
        self.tiltSensitivity = tiltSensitivity
        self.maxTiltAngle = maxTiltAngle
        self.pressedScale = pressedScale
    }
    
    public var body: some View {
        content
            .rotation3DEffect(.degrees(tiltY), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(tiltX), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(isPressed ? pressedScale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        // 基于拖动计算倾斜角度
                        let width = UIScreen.cc_active.bounds.width
                        let height = UIScreen.cc_active.bounds.height
                        
                        // 应用灵敏度因子并限制最大角度
                        tiltX = min(maxTiltAngle, max(-maxTiltAngle, value.translation.width / width * 100 * tiltSensitivity))
                        tiltY = min(maxTiltAngle, max(-maxTiltAngle, -value.translation.height / height * 100 * tiltSensitivity))
                    }
                    .onEnded { _ in
                        isDragging = false
                        // 平滑回到中心位置
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            tiltX = 0
                            tiltY = 0
                        }
                    }
            )
            .gesture(
                // 添加按压效果使卡片更有交互感
                TapGesture()
                    .onEnded {
                        withAnimation {
                            isPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    isPressed = false
                                }
                            }
                        }
                    }
            )
            .gesture(
                // 长按手势以增加倾斜效果
                LongPressGesture(minimumDuration: 0.2)
                    .onChanged { _ in
                        withAnimation(.easeIn(duration: 0.2)) {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPressed = false
                        }
                    }
            )
    }
} 

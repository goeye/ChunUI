#include <metal_stdlib>
using namespace metal;

// 简化的Simplex噪声函数
float3 permute_card(float3 x) {
    return fmod(((x * 34.0) + 1.0) * x, 289.0);
}

float snoise_card(float2 v) {
    const float4 C = float4(
        0.211324865405187, 0.366025403784439,
        -0.577350269189626, 0.024390243902439
    );
    float2 i = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = fmod(i, 289.0);

    float3 p = permute_card(
        permute_card(i.y + float3(0.0, i1.y, 1.0))
        + i.x + float3(0.0, i1.x, 1.0)
    );

    float3 m = max(
        0.5 - float3(
            dot(x0, x0),
            dot(x12.xy, x12.xy),
            dot(x12.zw, x12.zw)
        ),
        0.0
    );
    m = m * m;
    m = m * m;

    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);

    float3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// 优化的宝可梦卡片光谱颜色效果
float3 getPokemonHoloColors(float t, float variation, float3 color1, float3 color2, float3 color3, float3 color4, float3 color5, float3 color6) {
    // 使用传入的6个颜色，而不是静态数组
    float3 colors[6];
    colors[0] = color1;
    colors[1] = color2;
    colors[2] = color3;
    colors[3] = color4;
    colors[4] = color5;
    colors[5] = color6;

    // 平滑过渡的金属光泽效果
    float idx = t * 5.0 + variation;
    float frac = fract(idx);
    int idx1 = int(idx) % 6;
    int idx2 = (idx1 + 1) % 6;

    // 使用平滑过渡函数
    float blend = smoothstep(0.0, 1.0, frac);
    return mix(colors[idx1], colors[idx2], blend);
}

// 高级全息镭射卡片效果着色器
[[ stitchable ]] half4 holographicEffect(float2 position,
                                 half4 color,
                                 float time,
                                 float tiltX,
                                 float tiltY,
                                 float2 size,
                                 float intensity,
                                 float patternScale,
                                 float speedMultiplier,
                                 float3 color1,
                                 float3 color2,
                                 float3 color3,
                                 float3 color4,
                                 float3 color5,
                                 float3 color6) {
    // 归一化坐标，并调整宽高比
    float2 uv = position / size;
    uv = (uv - 0.5) * 2.0; // 范围从-1到1
    uv.x *= (size.x / size.y); // 宽高比校正

    // 增强的倾斜效果，更接近宝可梦卡片的反光效果
    float tiltEffect = (uv.x * tiltX + uv.y * tiltY) * 1.5;

    // 基础噪声模式 - 宝可梦卡片的横向光带效果
    float baseNoise = snoise_card(uv * patternScale * 0.5 + float2(time * 0.12 * speedMultiplier, time * 0.14 * speedMultiplier));

    // 创建由噪声控制的动态光带效果 - 横条纹光线效果
    float linePattern = sin((uv.y + baseNoise * 0.3) * 60.0 + tiltEffect * 3.0 + time * speedMultiplier);
    linePattern = pow(0.5 + 0.5 * linePattern, 3.0);

    // 细致纹理的第二层噪声 - 模拟光栅效果
    float detailNoise = snoise_card(uv * patternScale * 4.0 + float2(time * -0.18 * speedMultiplier, time * 0.22 * speedMultiplier));

    // 添加第三层更细致的纹理 - 模拟微观粒子散射
    float microNoise = snoise_card(uv * patternScale * 10.0 + float2(time * 0.3 * speedMultiplier, time * -0.25 * speedMultiplier));

    // 横向压缩的镭射线 - 宝可梦卡片的关键特征
    float hLines = smoothstep(0.35, 0.65, 0.5 + 0.5 * sin(uv.y * 100.0 - tiltEffect * 2.0 + time * 1.5 * speedMultiplier));

    // 将噪声混合以创建复杂的全息图效果
    float holographicPattern = mix(linePattern * 0.7, detailNoise * 0.6, 0.4);
    holographicPattern = mix(holographicPattern, microNoise * 0.5, 0.2);
    holographicPattern = mix(holographicPattern, hLines, 0.35);

    // 增强闪光效果，让某些区域更亮 - 增加游戏卡片的闪亮感
    float sparkle = pow(baseNoise * 0.5 + 0.5, 15.0) * sin(time * 3.0 * speedMultiplier);
    float sparkleMask = sin(uv.x * 5.0 + uv.y * 7.0 + time * 2.0) * 0.5 + 0.5;
    sparkle = sparkle * sparkleMask;
    holographicPattern = mix(holographicPattern, 1.0, sparkle * 0.5);

    // 应用宝可梦式彩虹镭射效果
    float colorVariation = baseNoise * 0.3;
    float3 holoColors = getPokemonHoloColors((uv.y * 0.5 + uv.x * 0.3) + baseNoise * 0.15 + time * 0.2 * speedMultiplier, colorVariation, color1, color2, color3, color4, color5, color6);

    // 基础颜色
    float3 baseColor = float3(color.r, color.g, color.b);

    // 混合原始颜色和全息效果，增强基于倾斜的效果
    float tiltIntensity = min(1.0, abs(tiltX) * 0.1 + abs(tiltY) * 0.1 + 0.3);
    float finalIntensity = intensity * tiltIntensity;
    float3 finalColor = mix(baseColor, holoColors, holographicPattern * finalIntensity);

    // 确保保留原始的alpha通道
    return half4(half3(finalColor), color.a);
}

// 为卡片边缘添加增强的发光效果
[[ stitchable ]] half4 cardGlowEffect(float2 position,
                               half4 color,
                               float2 size,
                               float time,
                               float glowWidth,
                               float glowIntensity,
                               float3 glowColor) {
    // 归一化坐标
    float2 uv = position / size;
    uv = (uv - 0.5) * 2.0; // 范围从-1到1

    // 计算到边缘的距离 - 使用矩形边缘而非圆角
    float distToEdge = 1.0 - max(abs(uv.x), abs(uv.y));
    distToEdge = 1.0 - smoothstep(-0.01, 0.01, -distToEdge);

    // 创建多层发光效果，模拟宝可梦卡片的边缘处理
    float outerGlow = smoothstep(0.0, glowWidth * 1.5, distToEdge) * (1.0 - smoothstep(glowWidth * 1.5, glowWidth * 3.0, distToEdge));
    float innerGlow = smoothstep(0.0, glowWidth * 0.8, distToEdge) * (1.0 - smoothstep(glowWidth * 0.8, glowWidth * 1.6, distToEdge));

    // 添加时间动画，使发光效果脉动并且交替变化
    float pulseOuter = (0.7 + 0.3 * sin(time * 1.5));
    float pulseInner = (0.7 + 0.3 * sin(time * 1.5 + 3.14159)); // 反相位

    // 双层发光效果
    float3 outerGlowRGB = float3(glowColor.x, glowColor.y, glowColor.z) * outerGlow * glowIntensity * pulseOuter;
    float3 innerGlowRGB = float3(1.0 - glowColor.z, 1.0 - glowColor.y, 1.0 - glowColor.x) * innerGlow * glowIntensity * 1.2 * pulseInner; // 互补色

    // 将发光效果添加到原始颜色上
    float3 finalColor = float3(color.r, color.g, color.b) + outerGlowRGB + innerGlowRGB;

    // 边缘高光效果 - 模拟金属边框
    float edgeHighlight = smoothstep(glowWidth * 0.9, glowWidth * 1.1, distToEdge) * 0.5;
    finalColor += float3(1.0, 1.0, 1.0) * edgeHighlight;

    return half4(half3(finalColor), color.a);
}

// 增强的镭射纹理效果 - 宝可梦卡片风格
[[ stitchable ]] half4 holographicTexture(float2 position,
                                 half4 color,
                                 float2 size,
                                 float time,
                                 float scale,
                                 float speed,
                                 float intensity,
                                 float3 color1,
                                 float3 color2,
                                 float3 color3,
                                 float3 color4,
                                 float3 color5,
                                 float3 color6) {
    // 归一化坐标
    float2 uv = position / size;

    // 创建交叉光栅纹理 - 宝可梦卡片的特征
    float gridX = sin(uv.x * 120.0 * scale + time * speed * 0.5) * 0.5 + 0.5;
    float gridY = sin(uv.y * 120.0 * scale - time * speed * 0.3) * 0.5 + 0.5;
    float grid = gridX * gridY;

    // 计算动态噪声纹理
    float pattern1 = snoise_card(uv * scale + float2(time * speed, time * speed * 0.5));
    float pattern2 = snoise_card(uv * scale * 2.0 + float2(-time * speed * 0.7, time * speed * 0.3));

    // 创建复杂纹理
    float finalPattern = (pattern1 * 0.5 + pattern2 * 0.3 + grid * 0.2);
    finalPattern = 0.5 + 0.5 * finalPattern; // 范围调整到0-1

    // 添加动态光点效果 - 模拟卡片表面微粒子
    float sparklePattern = pow(max(0.0, snoise_card(uv * scale * 8.0 + float2(time * speed * 2.0, 0.0))), 20.0) * 2.0;
    finalPattern = mix(finalPattern, 1.0, sparklePattern);

    // 生成彩虹颜色 - 使用更鲜艳的宝可梦卡片色调
    float colorVar = snoise_card(uv * scale * 0.2 + float2(0.0, time * speed * 0.1)) * 0.2;
    float3 holoColors = getPokemonHoloColors(finalPattern + time * 0.1, colorVar, color1, color2, color3, color4, color5, color6);

    // 计算镭射效果强度，基于原始颜色亮度和纹理
    float luminance = (color.r * 0.299 + color.g * 0.587 + color.b * 0.114);
    float effectStrength = luminance * intensity * (0.7 + 0.3 * finalPattern);

    // 创建方向性光泽效果 - 宝可梦卡片的特征
    float directionalSheen = pow(0.5 + 0.5 * sin(uv.y * 6.0 + time * speed * 0.8), 2.0);
    effectStrength *= (0.8 + 0.4 * directionalSheen);

    // 混合原始颜色和镭射效果
    float3 baseColor = float3(color.r, color.g, color.b);
    float3 finalColor = mix(baseColor, holoColors, finalPattern * effectStrength);

    // 添加高光闪点
    finalColor += float3(1.0, 1.0, 1.0) * sparklePattern * effectStrength;

    return half4(half3(finalColor), color.a);
}

// 添加宝可梦卡片风格的专用光泽线效果
[[ stitchable ]] half4 pokemonHoloLinesEffect(float2 position,
                                      half4 color,
                                      float2 size,
                                      float time,
                                      float tiltX,
                                      float tiltY,
                                      float intensity,
                                      float3 color1,
                                      float3 color2,
                                      float3 color3,
                                      float3 color4,
                                      float3 color5,
                                      float3 color6) {
    // 归一化坐标
    float2 uv = position / size;

    // 计算倾斜效应
    float tiltEffect = uv.x * tiltX + uv.y * tiltY;

    // 创建水平光泽线 - 宝可梦卡片的关键特征
    float lineCount = 30.0; // 线条数量
    float lineThickness = 0.3; // 线条厚度
    float linePhase = tiltEffect * 5.0 + time * 0.5; // 相位偏移

    // 生成光泽线
    float lines = 0.0;
    for (int i = 0; i < 3; i++) {
        float offset = float(i) * 0.33;
        float y = fract(uv.y * lineCount + linePhase + offset);
        lines += smoothstep(0.5 - lineThickness, 0.5, y) * smoothstep(0.5, 0.5 + lineThickness, y);
    }
    lines = min(1.0, lines);

    // 应用光泽颜色
    float colorIndex = uv.y * 0.2 + time * 0.1;
    float colorVar = snoise_card(uv * 1.5 + float2(time * 0.2, 0.0)) * 0.1;
    float3 lineColor = getPokemonHoloColors(colorIndex, colorVar, color1, color2, color3, color4, color5, color6);

    // 强度随倾斜角度变化
    float finalIntensity = intensity * (0.3 + min(1.0, abs(tiltX) * 0.2 + abs(tiltY) * 0.2));

    // 混合到原始颜色
    float3 baseColor = float3(color.r, color.g, color.b);
    float3 finalColor = mix(baseColor, lineColor, lines * finalIntensity);

    return half4(half3(finalColor), color.a);
}

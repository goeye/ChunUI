//
//  Beams.metal
//  YUI
//
//  光束效果着色器 - 从 React Three.js Beams 移植
//  斜向光束 + Perlin噪声扭曲 + 动态流动
//

#include <metal_stdlib>
using namespace metal;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 噪声函数
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

float beamHash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453123);
}

float beamNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float a = beamHash(i);
    float b = beamHash(i + float2(1.0, 0.0));
    float c = beamHash(i + float2(0.0, 1.0));
    float d = beamHash(i + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// 3D Perlin 噪声 (简化版)
float beamCnoise(float3 p) {
    float3 i = floor(p);
    float3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float n = i.x + i.y * 57.0 + i.z * 113.0;

    float a = beamHash(float2(n, 0.0));
    float b = beamHash(float2(n + 1.0, 0.0));
    float c = beamHash(float2(n + 57.0, 0.0));
    float d = beamHash(float2(n + 58.0, 0.0));
    float e = beamHash(float2(n + 113.0, 0.0));
    float ff = beamHash(float2(n + 114.0, 0.0));
    float g = beamHash(float2(n + 170.0, 0.0));
    float h = beamHash(float2(n + 171.0, 0.0));

    float x1 = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    float x2 = mix(mix(e, ff, f.x), mix(g, h, f.x), f.y);

    return mix(x1, x2, f.z) * 2.0 - 1.0;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Beams 光束效果
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[[ stitchable ]] half4 beams(
    float2 position,
    half4 color,
    float time,
    float2 size,
    float beamWidth,
    float beamCount,
    float speed,
    float noiseScale,
    float noiseIntensity,
    float rotation,
    float3 lightColor
) {
    // 归一化坐标到 [-1, 1]
    float2 uv = (position / size) * 2.0 - 1.0;

    // 旋转坐标
    float angle = rotation * 3.14159265 / 180.0;
    float cosA = cos(angle);
    float sinA = sin(angle);
    float2 rotatedUV = float2(
        uv.x * cosA - uv.y * sinA,
        uv.x * sinA + uv.y * cosA
    );

    // 扩展坐标范围以覆盖旋转后的区域
    rotatedUV *= 1.5;

    // 计算光束
    float totalWidth = beamCount * beamWidth;
    float beamX = fract((rotatedUV.x + totalWidth * 0.5) / beamWidth);
    float beamIndex = floor((rotatedUV.x + totalWidth * 0.5) / beamWidth);

    // 每个光束的随机偏移
    float beamOffset = beamHash(float2(beamIndex, 0.0)) * 300.0;

    // 3D 噪声坐标 (模拟原始shader的getPos)
    float3 noisePos = float3(
        0.0,
        rotatedUV.y - beamOffset * 0.01,
        rotatedUV.y + time * speed * 0.3
    ) * noiseScale;

    float noiseValue = beamCnoise(noisePos);

    // 光束亮度 (中心亮，边缘暗)
    float brightness = 1.0 - abs(beamX - 0.5) * 2.0;
    brightness = pow(brightness, 0.5); // 更柔和的边缘

    // 噪声调制亮度
    brightness *= 0.5 + noiseValue * 0.5;
    brightness = clamp(brightness, 0.0, 1.0);

    // 添加随机噪点 (模拟原始shader的dithering)
    float grain = beamHash(position + time) / 15.0 * noiseIntensity;

    // 最终颜色 (黑色基底 + 白色光)
    float3 finalColor = lightColor * brightness - grain;
    finalColor = clamp(finalColor, 0.0, 1.0);

    return half4(half3(finalColor), 1.0);
}

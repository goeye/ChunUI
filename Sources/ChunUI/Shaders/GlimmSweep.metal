//
//  GlimmSweep.metal
//  Chat0IM
//
//  [INPUT]: SwiftUI colorEffect 管线（position/color + res/time/progress/alpha/hueShift uniforms）
//  [OUTPUT]: glimmSweep 扫光片元——Laper glimm 库 WebGL 着色器逐字节移植（citrus 色板彩带 + 波动边缘 + 伪高程虹彩 + 菲涅尔/镜面高光，premultiplied 输出）
//  [POS]: DesignSystem/Shader 的转场扫光本体，被 CCSweepLight 覆盖窗消费
//  [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

#define GLIMM_PI 3.14159265359

// Laper PageTransitionProvider 装配常量（citrus 色板 + bandTight 18 / wave 0.55 / speed 0.8 / brightness 0.88 / swell 0.55）
constant float3 kPalA = float3(0.55, 0.61, 0.61);
constant float3 kPalB = float3(0.54, 0.41, 0.63);
constant float3 kPalC = float3(0.50, 0.50, 0.50);
constant float3 kPalD = float3(0.66, 0.92, 0.23);
constant float kBandTight  = 18.0;
constant float kWaveAmount = 0.55;
constant float kWaveSpeed  = 0.8;
constant float kBrightness = 0.88;
constant float kSwell      = 0.55;
constant float kPosStart   = -0.2;
constant float kPosEnd     = 1.2;

static inline float3 glimmPal(float t) {
    return kPalA + kPalB * cos(2.0 * GLIMM_PI * (kPalC * t + kPalD));
}

[[ stitchable ]] half4 glimmSweep(float2 position, half4 color,
                                  float2 res, float time, float progress,
                                  float alpha, float hueShift,
                                  float3 tint, float tintMix) {
    float2 uv = position / res;
    float axis  = uv.y;          // 纵向：自上而下扫过（SwiftUI y 向下增长，progress 0→1 即 顶→底）
    float cross = uv.x;          // 波动沿横向展开

    float pos = kPosStart + progress * (kPosEnd - kPosStart);
    float tw = time * kWaveSpeed;

    // 三重正弦叠加的带缘波动
    float waveX =
        sin(cross *  6.0 + tw * 1.3) * 0.020
      + sin(cross * 13.0 - tw * 0.9 + 1.4) * 0.012
      + sin(cross * 21.0 + tw * 1.7 + 2.6) * 0.006;
    waveX *= kWaveAmount;

    float d = (axis - pos) - waveX;
    float band = exp(-d * d * kBandTight);

    // 沿行进轴的伪高程斜率（刻意忽略 cross 链式项——保持自上而下干净的虹彩推移；纵向走 slope.y，glimm uDirection=1 分支）
    float dhDaxis = -2.0 * d * kBandTight * band;
    float3 N = normalize(float3(0.0, dhDaxis * 0.18, 1.0));

    float trail = clamp(0.5 - d * 1.3, 0.0, 1.0);
    trail = pow(trail, 2.5) * 0.30;
    float intensity = max(band * 0.95, trail);

    // 全屏贴边覆盖，仅留 1.5% 软融边
    float vfade = smoothstep(0.0, 0.015, cross) * smoothstep(1.0, 0.985, cross);

    // 色相随合成法线旋转——iOS name-drop 式虹彩
    float t = N.x * 0.45 + N.y * 0.30
            + axis * 1.4 + cross * 0.35
            + hueShift + time * 0.04;
    float3 col = glimmPal(t) * kBrightness;
    // 主题化：保留亮度起伏（虹彩/波带结构），色度整体换到宿主色轴
    float luma = dot(col, float3(0.299, 0.587, 0.114));
    col = mix(col, tint * (luma * 1.7), tintMix);

    // 固定主光 + 正视相机：稳定的峰顶高光
    float3 V = float3(0.0, 0.0, 1.0);
    float3 L = normalize(float3(0.35, 0.55, 0.9));
    float3 H = normalize(L + V);
    float NdotH = clamp(dot(N, H), 0.0, 1.0);
    float NdotV = clamp(dot(N, V), 0.0, 1.0);
    float fresnel = pow(1.0 - NdotV, 3.0);
    float spec    = pow(NdotH, 80.0);

    // 进出屏 20% → 中点 100% 的软入软出
    float entryFade = mix(0.2, 1.0, 4.0 * progress * (1.0 - progress));

    float bodyA = intensity * vfade * alpha * entryFade;
    float3 bodyPM = col * bodyA;

    float highMask = band * vfade * alpha * entryFade * kSwell;
    float3 highEmit = (col * fresnel * 0.55 + float3(spec) * 1.1) * highMask;
    float highA     = (fresnel * 0.4 + spec * 0.9) * highMask;

    return half4(half3(bodyPM + highEmit), half(min(bodyA + highA, 1.0)));
}

//
//  ColorBendsAurora.metal
//  Chat0IM
//
//  ColorBends 完整移植版（对齐 React Three.js 参考实现的全参数片元）：
//  旋转 / 预扭曲迭代 / 透明覆盖 alpha / 噪声 / intensity / bandWidth 一个不少。
//  双色带版本：MAX_COLORS 固化为 2，专供登录页两道主题色极光。
//

#include <metal_stdlib>
using namespace metal;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 单条色带权重：JS 循环体的逐色带核心（m0/m1 双采样按 warpStrength 混合）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

static float cba_bandWeight(float2 s, float t, float bandIndex,
                            float frequency, float warpStrength, float bandWidth) {
    float2 r = sin(1.5 * (s.yx * frequency) + 2.0 * cos(s * frequency));
    float m0 = length(r + sin(5.0 * r.y * frequency - 3.0 * t + bandIndex) / 4.0);

    float kBelow = clamp(warpStrength, 0.0, 1.0);
    float kMix = pow(kBelow, 0.3);
    float gain = 1.0 + max(warpStrength - 1.0, 0.0);

    float2 disp = (r - s) * kBelow;
    float2 warped = s + disp * gain;
    float m1 = length(warped + sin(5.0 * warped.y * frequency - 3.0 * t + bandIndex) / 4.0);

    float m = mix(m0, m1, kMix);
    return 1.0 - exp(-bandWidth / exp(bandWidth * m));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ColorBends 双色带极光（透明背景，预乘 alpha）
// rot: (cos, sin) 旋转向量，由 Swift 侧按角度换算，等价 JS 的 uRot
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[[ stitchable ]] half4 colorBendsAurora(
    float2 position,
    half4 color,
    float time,
    float2 size,
    float2 rot,
    float scale,
    float frequency,
    float warpStrength,
    float noiseLevel,
    float iterations,
    float intensity,
    float bandWidth,
    float3 color1,
    float3 color2
) {
    float t = time;
    float2 uv = position / size;
    // Metal 的 y 轴向下，翻转对齐 GLSL 的 vUv
    float2 p = float2(uv.x, 1.0 - uv.y) * 2.0 - 1.0;

    // 旋转（uPointer/parallax 是 web 鼠标交互，移动端无指针，恒为 0 直接略去）
    float2 rp = float2(p.x * rot.x - p.y * rot.y, p.x * rot.y + p.y * rot.x);
    float2 q = float2(rp.x * (size.x / size.y), rp.y);
    q /= max(scale, 0.0001);
    q /= 0.5 + 0.2 * dot(q, q);
    q += 0.2 * cos(t) - 7.56;

    // 预扭曲迭代：向正弦场吸附，迭代越多形态越柔
    int iterCount = int(iterations);
    for (int j = 0; j < 5; j++) {
        if (j >= iterCount - 1) { break; }
        float2 rr = sin(1.5 * (q.yx * frequency) + 2.0 * cos(q * frequency));
        q += (rr - q) * 0.15;
    }

    // 两条色带累积（对齐 JS uColorCount=2 分支）
    float2 s = q;
    float3 sumCol = float3(0.0);
    float cover = 0.0;

    s -= 0.01;
    float w0 = cba_bandWeight(s, t, 0.0, frequency, warpStrength, bandWidth);
    sumCol += color1 * w0;
    cover = max(cover, w0);

    s -= 0.01;
    float w1 = cba_bandWeight(s, t, 1.0, frequency, warpStrength, bandWidth);
    sumCol += color2 * w1;
    cover = max(cover, w1);

    float3 col = clamp(sumCol, 0.0, 1.0) * intensity;

    // 胶片噪声去色带
    if (noiseLevel > 0.0001) {
        float n = fract(sin(dot(position + float2(time), float2(12.9898, 78.233))) * 43758.5453123);
        col += (n - 0.5) * noiseLevel;
        col = clamp(col, 0.0, 1.0);
    }

    // 透明模式：cover 即 alpha，预乘输出
    float a = cover;
    return half4(half3(col * a), half(a));
}

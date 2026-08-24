//
//  CCGradientWaves.metal
//  ChunUI
//
/**
 * [INPUT]: 依赖 CCGradientWavesView 经 MTKView 管线灌入的 WaveUniforms（分辨率/时间/能量/三色/参数）
 * [OUTPUT]: 对外提供 ccGradientWavesVertex 全屏三角 + ccGradientWavesFragment 倒挂等离子体海面（预乘 alpha，直接混到透明层）
 * [POS]: Shaders 的发言涟漪氛围 shader，只被 Effects/CCGradientWavesView 的渲染器消费；经典管线编译（SPM 自动入 Bundle.module 的 default.metallib），杜绝 stitchable 静默失效
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

#include <metal_stdlib>
using namespace metal;

// React Bits GradientWaves（ogl/WebGL2）同构：等离子体海面 raymarch。
// uv.y 翻转让海面倒挂在屏幕上方；步进压到 40，手机稳跑；无鼠标视差。
// energy（0…1，打字发言）在片元内统一调制振幅/湍流/速度/亮度 + 相机微抖。

constant float MAX_DIST = 20000.0;

// ━━━ Swift WaveRenderer 侧 WaveUniforms 同构布局（float2 对齐 8 / float4 对齐 16）━━━
struct WaveUniforms {
    float2 resolution;   // drawable 像素
    float  time;         // 秒
    float  energy;       // 发言能量 0…1（渲染器已平滑）
    float4 horizon;      // 远景色 rgb
    float4 wave;         // 浪身色 rgb
    float4 crest;        // 浪尖色 rgb
    float4 params;       // opacity, brightness, 备用×2
};

static float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float plasma(float3 r, float2 freq, float4 tc, float amplitude, float swell, float turbulence, float height) {
    float mx = r.x + tc.x;
    mx += swell * sin((r.y + mx) / 20.0 + tc.y);
    float my = r.y - tc.z;
    my += turbulence * cos(r.x / 23.0 + tc.w);
    return r.z - (sin(mx * freq.x) * amplitude + sin(my * freq.y) * amplitude + height);
}

static float raymarch(float3 pos, float3 dir, float2 freq, float4 tc,
                      float amplitude, float swell, float turbulence, float height) {
    float dist = 0.0;
    for (int i = 0; i < 128; i++) {
        if (float(i) >= 70.0) break;   // 原版 medium 步进；40 步浪形糊成雾
        float dscene = plasma(pos + dist * dir, freq, tc, amplitude, swell, turbulence, height);
        if (abs(dscene) < 0.1) break;
        dist += 0.9 * dscene;
        if (!(abs(dist) < MAX_DIST)) return MAX_DIST;
    }
    return dist;
}

// ━━━ 全屏三角（无顶点缓冲，vid 生成）━━━

struct WaveVertexOut {
    float4 position [[position]];
};

vertex WaveVertexOut ccGradientWavesVertex(uint vid [[vertex_id]]) {
    // (-1,-1) (3,-1) (-1,3) 三点盖满 NDC
    float2 ndc = float2(vid == 1 ? 3.0 : -1.0, vid == 2 ? 3.0 : -1.0);
    WaveVertexOut out;
    out.position = float4(ndc, 0.0, 1.0);
    return out;
}

fragment half4 ccGradientWavesFragment(WaveVertexOut in [[stage_in]],
                                     constant WaveUniforms &u [[buffer(0)]]) {
    float E = clamp(u.energy, 0.0, 1.0);
    // 能量调制（原 SwiftUI 侧的参数曲线收拢进片元，单一真相）
    float uSpeed = 0.4 + 0.5 * E;
    float uAmplitude = 3.4 + 1.2 * E;
    float uWaveScale = 0.55;
    float uWaveRatio = 0.9;
    float uSwell = 35.0 + 18.0 * E;
    float uTurbulence = 24.0 + 22.0 * E;
    float uTilt = 1.11 + 0.08 * E;
    float uZoom = 1.05;
    float uHeight = 5.5;
    float uFogDepth = 15.0;
    float uBrightness = u.params.y + 0.12 * E;
    float uOpacity = u.params.x + 0.12 * E;
    float uGrain = 0.04 + 0.07 * E;

    float T = u.time * uSpeed;
    float2 freq = float2(uWaveScale / 7.0, (uWaveScale * uWaveRatio) / 3.0);
    float4 tc = float4(T / 0.130, T / 0.810, T / 0.200, T / 0.710);

    float vfov = (3.14159 / 2.3) / max(uZoom, 0.05);
    float3 cam = float3(0.0, 0.0, 30.0);
    float2 uv = (in.position.xy / max(u.resolution, float2(1.0))) - 0.5;
    uv.x *= u.resolution.x / max(u.resolution.y, 1.0);
    // 倒挂：海面挂在屏幕上方
    uv.y = -uv.y;
    // 发言微抖：能量驱动的相机抖动（原 view offset 抖动收进管线）
    uv += E * 0.012 * float2(sin(u.time * 47.0), cos(u.time * 31.0));

    float3 dir = float3(0.0, 0.0, -1.0);
    float ulen = length(uv);
    float xrot = vfov * ulen;
    float c = cos(xrot);
    float s = sin(xrot);
    dir = float3x3(float3(1.0, 0.0, 0.0), float3(0.0, c, -s), float3(0.0, s, c)) * dir;
    float2 nuv = ulen > 1e-5 ? uv / ulen : float2(1.0, 0.0);
    c = nuv.x;
    s = nuv.y;
    dir = float3x3(float3(c, -s, 0.0), float3(s, c, 0.0), float3(0.0, 0.0, 1.0)) * dir;
    c = cos(uTilt);
    s = sin(uTilt);
    dir = float3x3(float3(c, 0.0, s), float3(0.0, 1.0, 0.0), float3(-s, 0.0, c)) * dir;

    float dist = raymarch(cam, dir, freq, tc, uAmplitude, uSwell, uTurbulence, uHeight);
    float3 pos = cam + dist * dir;

    float t = clamp(uFogDepth / max(dist, 0.001), 0.0, 1.0);
    // 以浪心为轴展开色带：波谷=wave 波峰=crest，层次全幅拉开
    float3 body = mix(u.wave.xyz, u.crest.xyz, clamp((pos.z - uHeight) * 0.28 + 0.5, 0.0, 1.0));
    // horizon→body 过渡走 smoothstep：远景压 horizon、近景全 body，层级分明
    float3 col = mix(u.horizon.xyz, body, smoothstep(0.10, 0.80, t));
    col = clamp(col * uBrightness, 0.0, 1.0);

    float alpha = t * uOpacity;
    // 只占屏顶 1/3：0.24 处开始收，1/3 前干净归零
    float ny = in.position.y / max(u.resolution.y, 1.0);
    alpha *= 1.0 - smoothstep(0.24, 0.34, ny);
    float g = hash21(in.position.xy + fmod(u.time, 64.0) * 11.0);
    alpha += (g - 0.5) * uGrain;
    alpha = clamp(alpha, 0.0, 1.0);

    // 预乘 alpha 直接混到透明 MTKView 层
    return half4(half3(col) * half(alpha), half(alpha));
}

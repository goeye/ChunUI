//
//  Silk.metal
//  YUI
//
//  Silk effect shader - ported from React Three.js Silk
//  Wavy silk texture + Perlin noise + dynamic flow
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Permutation Table (mod289 optimized)

float3 silkMod289_f3(float3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 silkMod289_f4(float4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 silkPermute(float4 x) {
    return silkMod289_f4(((x * 34.0) + 10.0) * x);
}

float4 silkTaylorInvSqrt(float4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

// MARK: - Simplex Noise 3D

float silkSnoise(float3 v) {
    const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
    const float4 D = float4(0.0, 0.5, 1.0, 2.0);

    // First corner
    float3 i = floor(v + dot(v, float3(C.y)));
    float3 x0 = v - i + dot(i, float3(C.x));

    // Other corners
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    float3 x1 = x0 - i1 + C.x;
    float3 x2 = x0 - i2 + C.y;
    float3 x3 = x0 - D.yyy;

    // Permutations
    i = silkMod289_f3(i);
    float4 p = silkPermute(silkPermute(silkPermute(
        i.z + float4(0.0, i1.z, i2.z, 1.0)) +
        i.y + float4(0.0, i1.y, i2.y, 1.0)) +
        i.x + float4(0.0, i1.x, i2.x, 1.0));

    // Gradients: 7x7 points over a square, mapped onto an octahedron
    float n_ = 0.142857142857; // 1.0/7.0
    float3 ns = n_ * D.wyz - D.xzx;

    float4 j = p - 49.0 * floor(p * ns.z * ns.z);

    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_);

    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);

    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);

    float4 s0 = floor(b0) * 2.0 + 1.0;
    float4 s1 = floor(b1) * 2.0 + 1.0;
    float4 sh = -step(h, float4(0.0));

    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);

    // Normalise gradients
    float4 norm = silkTaylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    float4 m = max(0.5 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 105.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// MARK: - Silk Effect

[[ stitchable ]] half4 silk(
    float2 position,
    half4 color,
    float time,
    float2 size,
    float speed,
    float noiseScale,
    float noiseIntensity,
    float rotation,
    float3 baseColor
) {
    // Normalize coordinates
    float2 uv = position / size;

    // Rotate coordinates
    float angle = rotation * 3.14159265 / 180.0;
    float cosA = cos(angle);
    float sinA = sin(angle);
    float2 center = float2(0.5, 0.5);
    float2 centeredUV = uv - center;
    float2 rotatedUV = float2(
        centeredUV.x * cosA - centeredUV.y * sinA,
        centeredUV.x * sinA + centeredUV.y * cosA
    );
    rotatedUV += center;

    // 3D noise coordinates
    float3 noisePos = float3(
        rotatedUV.x * noiseScale,
        rotatedUV.y * noiseScale,
        time * speed * 0.1
    );

    // Multi-layer Simplex noise (FBM)
    float noise1 = silkSnoise(noisePos);
    float noise2 = silkSnoise(noisePos * 2.0 + float3(100.0, 0.0, 0.0)) * 0.5;
    float noise3 = silkSnoise(noisePos * 4.0 + float3(0.0, 100.0, 0.0)) * 0.25;

    float combinedNoise = (noise1 + noise2 + noise3) * noiseIntensity;

    // Silk wave effect
    float wave = sin(rotatedUV.y * 10.0 + combinedNoise * 3.0 + time * speed * 0.5);
    wave = wave * 0.5 + 0.5;

    // Brightness modulation
    float brightness = 0.3 + wave * 0.4 + combinedNoise * 0.2;
    brightness = clamp(brightness, 0.0, 1.0);

    // Apply color
    float3 finalColor = baseColor * brightness;

    // Add subtle highlight
    float highlight = pow(wave, 3.0) * 0.3;
    finalColor += float3(highlight);

    finalColor = clamp(finalColor, 0.0, 1.0);

    return half4(half3(finalColor), 1.0);
}

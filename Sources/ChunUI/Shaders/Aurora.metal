#include <metal_stdlib>
using namespace metal;

// 简化的Simplex噪声函数（使用唯一命名避免冲突）
float3 aurora_permute(float3 x) {
    return fmod(((x * 34.0) + 1.0) * x, 289.0);
}

float aurora_snoise(float2 v) {
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

    float3 p = aurora_permute(
        aurora_permute(i.y + float3(0.0, i1.y, 1.0))
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

// 计算色阶插值
float3 colorRamp(float3 colors[3], float factor) {
    int index = 0;
    // 找到当前位置所在的颜色区间
    for (int i = 0; i < 2; i++) {
        float position = i == 0 ? 0.0 : (i == 1 ? 0.5 : 1.0);
        bool isInBetween = position <= factor;
        index = int(mix(float(index), float(i), float(isInBetween)));
    }
    
    // 获取区间的两个颜色
    float3 currentColor = colors[index];
    float3 nextColor = colors[index + 1];
    
    // 计算当前位置在区间中的比例
    float currentPosition = index == 0 ? 0.0 : (index == 1 ? 0.5 : 1.0);
    float nextPosition = index == 0 ? 0.5 : 1.0;
    float range = nextPosition - currentPosition;
    float lerpFactor = (factor - currentPosition) / range;
    
    // 对两个颜色进行插值
    return mix(currentColor, nextColor, lerpFactor);
}

// Aurora效果着色器
[[ stitchable ]] half4 aurora(float2 position, 
                      half4 color,
                      float time,
                      float amplitude,
                      float3 colorStop1,
                      float3 colorStop2,
                      float3 colorStop3,
                      float2 resolution,
                      float blend) {
    float2 uv = position / resolution;
    
    // 设置颜色停止点
    float3 colorStops[3] = {colorStop1, colorStop2, colorStop3};
    
    // 计算颜色渐变
    float3 rampColor = colorRamp(colorStops, uv.x);
    
    // 使用噪声函数创建波动效果（x 系数决定波长：1.2 比原 2.0 波形更舒展，波峰不尖锐）
    float height = aurora_snoise(float2(uv.x * 1.2 + time * 0.1, time * 0.25)) * 0.5 * amplitude;
    height = exp(height);
    height = (uv.y * 2.0 - height + 0.2);
    float intensity = 0.6 * height;
    
    // 控制极光的过渡边缘
    float midPoint = 0.20;
    float auroraAlpha = smoothstep(midPoint - blend * 0.5, midPoint + blend * 0.5, intensity);
    
    // 计算极光颜色：不再用 intensity 直接压暗 ramp（低强度区会糊成黑影），
    // 保持基础亮度 ≥0.85，并在高强度处向白色提亮出光晕
    float glow = clamp(intensity, 0.0, 1.4);
    float3 auroraColor = rampColor * (0.85 + 0.35 * glow);
    auroraColor = mix(auroraColor, float3(1.0), 0.22 * smoothstep(0.6, 1.4, glow));
    
    // 返回带有预乘alpha的结果
    return half4(half3(auroraColor * auroraAlpha), half(auroraAlpha));
}

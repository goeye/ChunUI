#include <metal_stdlib>
using namespace metal;

float getMetaBallValue(float2 c, float r, float2 p) {
    float2 d = p - c;
    float dist2 = dot(d, d);
    return (r * r) / dist2;
}

// 使用stitchable标记以便SwiftUI的ShaderLibrary可以使用它
[[ stitchable ]] half4 metaBalls(float2 position,
                                half4 color,
                                float time,
                                float2 size,
                                float3 ballColor,
                                float animationSize,
                                float ballCount,
                                float clumpFactor) {
    float2 coord = (position - size * 0.5) * (animationSize / size.y);
    
    float m1 = 0.0;
    
    // 创建多个MetaBall
    for (int i = 0; i < int(ballCount); i++) {
        // 使用简单的哈希函数创建伪随机参数
        float st = fract(float(i) * 0.1031) * (2.0 * M_PI_F);
        float dtFactor = 0.1 * M_PI_F + fract(float(i) * 0.1030) * (0.4 * M_PI_F - 0.1 * M_PI_F);
        float baseScale = 5.0 + fract(float(i) * 0.0973) * (10.0 - 5.0);
        float toggle = floor(fract(float(i) * 0.5321) * 2.0);
        float radius = 0.5 + fract(float(i) * 0.3721) * (2.0 - 0.5);
        
        // 计算位置
        float dt = time * dtFactor;
        float th = st + dt;
        float x = cos(th);
        float y = sin(th + dt * toggle);
        
        float2 pos = float2(x, y) * baseScale * clumpFactor;
        
        // 添加每个球体的贡献
        m1 += getMetaBallValue(pos, radius, coord);
    }
    
    float total = m1;
    float f = smoothstep(-1.0, 1.0, (total - 1.3) / min(1.0, fwidth(total)));
    
    half3 finalColor = half3(ballColor.x, ballColor.y, ballColor.z) * half(f);
    
    // 支持透明度
    return half4(finalColor, f);
} 

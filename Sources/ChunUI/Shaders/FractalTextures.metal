//
//  FractalTextures.metal
//  Chat0IM
//
//  订阅卡右下角的点阵分形纹理（ASCII/halftone 风）：
//  逐 6pt 网格采样分形强度，以强度决定圆点半径与明度，无任何连续色块背景。
//  Pro   → Julia 集（z² + c，c 缓慢巡游）
//  Max   → Newton 分形（z³ - 1 = 0 收敛盆地）
//  Crazy → Mandelbrot 海马谷（边界深放大，呼吸式微缩放）
//

#include <metal_stdlib>
using namespace metal;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 复数工具
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

static inline float2 ftx_cmul(float2 a, float2 b) {
    return float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

static inline float2 ftx_cdiv(float2 a, float2 b) {
    float d = dot(b, b);
    return float2(dot(a, b), a.y * b.x - a.x * b.y) / max(d, 1e-9);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 三种分形的标量强度（0..1，在网格中心采样一次）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

static float ftx_juliaIntensity(float2 uv, float time) {
    float angle = 0.62 + time * 0.05;
    float2 c = 0.7885 * float2(cos(angle), sin(angle));

    float2 z = uv * 3.1;
    const int maxIter = 48;
    int i = 0;
    for (; i < maxIter; i++) {
        z = ftx_cmul(z, z) + c;
        if (dot(z, z) > 16.0) { break; }
    }
    if (i >= maxIter) { return 1.0; }

    float escape = float(i) - log2(log2(dot(z, z))) + 4.0;
    return pow(clamp(escape / float(maxIter), 0.0, 1.0), 1.5);
}

static float ftx_newtonIntensity(float2 uv, float time) {
    float rot = time * 0.03;
    float cs = cos(rot), sn = sin(rot);
    float2 p = uv * 2.6;
    float2 z = float2(p.x * cs - p.y * sn, p.x * sn + p.y * cs);

    const float2 roots[3] = {
        float2(1.0, 0.0),
        float2(-0.5, 0.8660254),
        float2(-0.5, -0.8660254)
    };

    const int maxIter = 26;
    int basin = 0;
    float steps = float(maxIter);
    for (int i = 0; i < maxIter; i++) {
        float2 z2 = ftx_cmul(z, z);
        float2 z3 = ftx_cmul(z2, z);
        z = z - ftx_cdiv(z3 - float2(1.0, 0.0), 3.0 * z2);

        bool converged = false;
        for (int r = 0; r < 3; r++) {
            if (distance(z, roots[r]) < 0.001) {
                basin = r;
                steps = float(i);
                converged = true;
                break;
            }
        }
        if (converged) { break; }
    }

    // 盆地边界（收敛慢）最亮，三个盆地给出层次差
    float edge = clamp(steps / 13.0, 0.0, 1.0);
    return clamp((0.30 + 0.70 * edge) * (0.70 + 0.15 * float(basin)), 0.0, 1.0);
}

static float ftx_mandelbrotIntensity(float2 uv, float time) {
    float zoom = 0.022 * (1.0 + 0.12 * sin(time * 0.18));
    float2 c = float2(-0.7453, 0.1127) + uv * zoom;

    float2 z = float2(0.0);
    const int maxIter = 72;
    int i = 0;
    for (; i < maxIter; i++) {
        z = ftx_cmul(z, z) + c;
        if (dot(z, z) > 16.0) { break; }
    }
    if (i >= maxIter) { return 0.9; }

    float escape = float(i) - log2(log2(dot(z, z))) + 4.0;
    float t = clamp(escape / float(maxIter), 0.0, 1.0);
    float band = 0.5 + 0.5 * cos(t * 18.0 - 1.2);
    return clamp(pow(t, 1.1) * (0.55 + 0.45 * band), 0.0, 1.0);
}

// ━━━ Burning Ship：|Re|+i|Im| 的火焰船体，帆影处细节最密 ━━━
static float ftx_burningShipIntensity(float2 uv, float time) {
    float zoom = 0.9 * (1.0 + 0.06 * sin(time * 0.15));
    float2 c = float2(-1.755, -0.03) + uv * float2(0.14, 0.10) * zoom;
    float2 z = float2(0.0);
    const int maxIter = 64;
    int i = 0;
    for (; i < maxIter; i++) {
        z = float2(fabs(z.x), fabs(z.y));
        z = ftx_cmul(z, z) + c;
        if (dot(z, z) > 16.0) { break; }
    }
    if (i >= maxIter) { return 0.92; }
    float escape = float(i) - log2(log2(dot(z, z))) + 4.0;
    float t = clamp(escape / float(maxIter), 0.0, 1.0);
    return clamp(pow(t, 1.2) * (0.5 + 0.5 * cos(t * 14.0 - 0.8)) + 0.18, 0.0, 1.0);
}

// ━━━ Tricorn（Mandelbar）：共轭迭代的三角对称怪物 ━━━
static float ftx_tricornIntensity(float2 uv, float time) {
    float rot = time * 0.04;
    float cs = cos(rot), sn = sin(rot);
    float2 p = uv * 2.4;
    float2 c = float2(p.x * cs - p.y * sn, p.x * sn + p.y * cs) + float2(-0.28, 0.0);
    float2 z = float2(0.0);
    const int maxIter = 56;
    int i = 0;
    for (; i < maxIter; i++) {
        z = float2(z.x, -z.y);          // 共轭
        z = ftx_cmul(z, z) + c;
        if (dot(z, z) > 16.0) { break; }
    }
    if (i >= maxIter) { return 0.95; }
    float escape = float(i) - log2(log2(dot(z, z))) + 4.0;
    return pow(clamp(escape / float(maxIter), 0.0, 1.0), 1.35);
}

// ━━━ Celtic：|Re(z²)| 折叠出的凯尔特结晶 ━━━
static float ftx_celticIntensity(float2 uv, float time) {
    float zoom = 1.0 + 0.08 * sin(time * 0.14);
    float2 c = float2(-0.51, -0.53) + uv * 1.15 * zoom;
    float2 z = float2(0.0);
    const int maxIter = 56;
    int i = 0;
    for (; i < maxIter; i++) {
        float2 z2 = ftx_cmul(z, z);
        z = float2(fabs(z2.x), z2.y) + c;
        if (dot(z, z) > 16.0) { break; }
    }
    if (i >= maxIter) { return 0.9; }
    float escape = float(i) - log2(log2(dot(z, z))) + 4.0;
    float t = clamp(escape / float(maxIter), 0.0, 1.0);
    return clamp(pow(t, 1.15) * (0.55 + 0.45 * cos(t * 20.0)), 0.0, 1.0);
}

// ━━━ Phoenix：带记忆项的凤凰羽翼（z² + c + p·z_{n-1}）━━━
static float ftx_phoenixIntensity(float2 uv, float time) {
    float2 c = float2(0.5667, 0.0);
    float2 pcoef = float2(-0.5, 0.0);
    float rot = 1.5707963 + 0.05 * sin(time * 0.12);
    float cs = cos(rot), sn = sin(rot);
    float2 p0 = uv * 2.7;
    float2 z = float2(p0.x * cs - p0.y * sn, p0.x * sn + p0.y * cs);
    float2 zPrev = float2(0.0);
    const int maxIter = 52;
    int i = 0;
    for (; i < maxIter; i++) {
        float2 zNext = ftx_cmul(z, z) + c + ftx_cmul(pcoef, zPrev);
        zPrev = z;
        z = zNext;
        if (dot(z, z) > 16.0) { break; }
    }
    if (i >= maxIter) { return 1.0; }
    float escape = float(i) - log2(log2(dot(z, z))) + 4.0;
    return pow(clamp(escape / float(maxIter), 0.0, 1.0), 1.4);
}

// ━━━ Multibrot z³：三重对称的高阶曼德博 ━━━
static float ftx_multibrot3Intensity(float2 uv, float time) {
    float zoom = 1.0 + 0.07 * sin(time * 0.16);
    float2 c = uv * 2.3 * zoom + float2(-0.08, 0.0);
    float2 z = float2(0.0);
    const int maxIter = 56;
    int i = 0;
    for (; i < maxIter; i++) {
        z = ftx_cmul(ftx_cmul(z, z), z) + c;
        if (dot(z, z) > 16.0) { break; }
    }
    if (i >= maxIter) { return 0.92; }
    float escape = float(i) - log2(log2(dot(z, z))) / 1.585 + 3.0;
    float t = clamp(escape / float(maxIter), 0.0, 1.0);
    return clamp(pow(t, 1.2) * (0.6 + 0.4 * cos(t * 16.0 - 0.6)), 0.0, 1.0);
}

// ━━━ Newton z⁴：四根收敛盆地的十字风车 ━━━
static float ftx_newton4Intensity(float2 uv, float time) {
    float rot = time * 0.035;
    float cs = cos(rot), sn = sin(rot);
    float2 p = uv * 2.4;
    float2 z = float2(p.x * cs - p.y * sn, p.x * sn + p.y * cs);
    const float2 roots[4] = {
        float2(1.0, 0.0), float2(-1.0, 0.0), float2(0.0, 1.0), float2(0.0, -1.0)
    };
    const int maxIter = 26;
    int basin = 0;
    float steps = float(maxIter);
    for (int i = 0; i < maxIter; i++) {
        float2 z2 = ftx_cmul(z, z);
        float2 z3 = ftx_cmul(z2, z);
        float2 z4 = ftx_cmul(z2, z2);
        z = z - ftx_cdiv(z4 - float2(1.0, 0.0), 4.0 * z3);
        bool converged = false;
        for (int r = 0; r < 4; r++) {
            if (distance(z, roots[r]) < 0.001) {
                basin = r; steps = float(i); converged = true; break;
            }
        }
        if (converged) { break; }
    }
    float edge = clamp(steps / 13.0, 0.0, 1.0);
    return clamp((0.28 + 0.72 * edge) * (0.66 + 0.11 * float(basin)), 0.0, 1.0);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 点阵渲染：强度 → 网格圆点半径/明度，其余全透明
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

constant float FTX_CELL = 6.0;

static half4 ftx_halftone(float2 position, float2 size, float time, float3 tint, int kind) {
    // 网格中心采样：整格共享同一强度，圆点才是正圆
    float2 cellIndex = floor(position / FTX_CELL);
    float2 cellCenter = (cellIndex + 0.5) * FTX_CELL;
    float2 uv = cellCenter / size - 0.5;

    float v;
    if (kind == 0) { v = ftx_juliaIntensity(uv, time); }
    else if (kind == 1) { v = ftx_newtonIntensity(uv, time); }
    else if (kind == 2) { v = ftx_mandelbrotIntensity(uv, time); }
    else if (kind == 3) { v = ftx_burningShipIntensity(uv, time); }
    else if (kind == 4) { v = ftx_tricornIntensity(uv, time); }
    else if (kind == 5) { v = ftx_celticIntensity(uv, time); }
    else if (kind == 6) { v = ftx_phoenixIntensity(uv, time); }
    else if (kind == 7) { v = ftx_multibrot3Intensity(uv, time); }
    else { v = ftx_newton4Intensity(uv, time); }

    // 低强度网格直接留白，保持点阵疏朗干净
    if (v < 0.14) { return half4(0.0); }

    float radius = FTX_CELL * 0.5 * (0.28 + 0.62 * v);
    float d = distance(position, cellCenter);
    float coverage = 1.0 - smoothstep(radius - 0.7, radius + 0.5, d);
    if (coverage <= 0.0) { return half4(0.0); }

    float a = coverage * (0.35 + 0.6 * v);
    float3 rgb = tint * (0.55 + 0.45 * v);
    return half4(half3(rgb * a), half(a));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - stitchable 入口
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[[ stitchable ]] half4 fractalJulia(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 0);
}

[[ stitchable ]] half4 fractalNewton(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 1);
}

[[ stitchable ]] half4 fractalMandelbrot(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 2);
}

[[ stitchable ]] half4 fractalBurningShip(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 3);
}

[[ stitchable ]] half4 fractalTricorn(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 4);
}

[[ stitchable ]] half4 fractalCeltic(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 5);
}

[[ stitchable ]] half4 fractalPhoenix(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 6);
}

[[ stitchable ]] half4 fractalMultibrot3(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 7);
}

[[ stitchable ]] half4 fractalNewton4(
    float2 position, half4 color,
    float2 size, float time, float3 tint
) {
    return ftx_halftone(position, size, time, tint, 8);
}

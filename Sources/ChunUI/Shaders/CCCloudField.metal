/**
 * [INPUT]: 依赖 Effects/CCCloudField 经 MTKView 灌入的 CloudUniforms（分辨率/DPR/时间/8 元球/包围盒/扫光/余弦调色板）
 * [OUTPUT]: 对外提供 ccCloudFieldVertex 全屏三角 + ccCloudFieldFragment 体积云近似（元球骨架 × 三层絮状密度 × 指数透射，预乘 alpha）
 * [POS]: Shaders 的 Cromma 舷窗白云；只被 Effects/CCCloudField 的渲染器消费。几何以 CSS px 传入，片元按 uDpr 换算。经典管线（非 stitchable）
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

#include <metal_stdlib>
using namespace metal;

constant float PI = 3.14159265359;

struct CloudUniforms {
    float2 resolution;
    float  dpr;
    float  time;
    float4 blobs[8];
    float4 box;
    float  alpha;
    float  shadow;
    float  scale;
    float  count;
    float  sweep;
    float  sweepAlpha;
    float  pad0;
    float  pad1;
    float4 palA;
    float4 palB;
    float4 palC;
    float4 palD;
};

struct CloudVertexOut {
    float4 position [[position]];
};

vertex CloudVertexOut ccCloudFieldVertex(uint vid [[vertex_id]]) {
    float2 ndc = float2(vid == 1 ? 3.0 : -1.0, vid == 2 ? 3.0 : -1.0);
    CloudVertexOut out;
    out.position = float4(ndc, 0.0, 1.0);
    return out;
}

static float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

static float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + float2(1.0, 0.0)), u.x),
               mix(hash(i + float2(0.0, 1.0)), hash(i + float2(1.0, 1.0)), u.x), u.y);
}

static float fbm(float2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = p * 2.02 + float2(13.0, 7.0);
        a *= 0.5;
    }
    return v;
}

static float field(float2 p, constant CloudUniforms &u) {
    float f = 0.0;
    int n = int(u.count);
    for (int i = 0; i < 8; i++) {
        if (i >= n) break;
        float4 b = u.blobs[i];
        if (b.z <= 0.5) continue;
        float2 d = p - b.xy;
        f += b.z * b.z / (dot(d, d) + 1.0);
    }
    return f;
}

static float ridged(float2 q) {
    float n = 0.65 * noise(q * 3.1) + 0.35 * noise(q * 6.3 + float2(2.0, 5.0));
    return abs(2.0 * n - 1.0);
}

static float layer(float2 p, float2 q, float lo, float hi, constant CloudUniforms &u) {
    float body = smoothstep(0.42, 1.5, field(p, u));
    float n = fbm(q);
    float base = body * smoothstep(lo, hi, n + body * 0.32);
    float edgeZone = (1.0 - base) * smoothstep(0.0, 0.35, base);
    return clamp(base - ridged(q + 3.7) * 0.32 * edgeZone, 0.0, 1.0);
}

static float extinct(float d, float sigma) {
    return 1.0 - exp(-d * sigma);
}

static void over(thread float3 &col, thread float &a, float3 c, float ca) {
    float na = ca + a * (1.0 - ca);
    col = (c * ca + col * a * (1.0 - ca)) / max(na, 1e-4);
    a = na;
}

static float3 pal(float t, constant CloudUniforms &u) {
    return u.palA.xyz + u.palB.xyz * cos(2.0 * PI * (u.palC.xyz * t + u.palD.xyz));
}

fragment float4 ccCloudFieldFragment(CloudVertexOut in [[stage_in]],
                                    constant CloudUniforms &u [[buffer(0)]]) {
    float2 p = float2(in.position.x, u.resolution.y - in.position.y) / max(u.dpr, 1e-4);
    float t = u.time;
    float s = max(u.scale, 1e-4);

    float unit = 260.0 / s;
    float2 q0 = p / unit;
    float2 flow = float2(fbm(q0 * 0.55 + float2(t * 0.035, 0.0)),
                         fbm(q0 * 0.55 + float2(7.3, 2.9) - float2(0.0, t * 0.03))) - 0.5;
    float2 q = q0 + flow * 0.9 + float2(t * 0.045, t * 0.01);

    float2 L = normalize(float2(-0.6, -1.0));
    float2 Lp = L * (30.0 / s);
    float2 Lq = Lp / unit;

    float2 qb = q * 0.8 + float2(3.1, 1.7) - float2(t * 0.012, 0.0);
    float2 qm = q * 1.25 + float2(11.4, 5.2) + float2(t * 0.02, 0.0);
    float2 qf = q * 1.9 + float2(21.7, 9.9) + float2(t * 0.035, -t * 0.01);
    float db = layer(p, qb, 0.28, 0.70, u);
    float dm = layer(p, qm, 0.36, 0.78, u);
    float df = layer(p, qf, 0.46, 0.84, u);
    float dbL = layer(p + Lp, qb + Lq * 0.8, 0.28, 0.70, u);
    float dmL = layer(p + Lp, qm + Lq * 1.25, 0.36, 0.78, u);
    float dfL = layer(p + Lp, qf + Lq * 1.9, 0.46, 0.84, u);
    float occM = smoothstep(0.05, 0.7, layer(p + float2(-10.0, -16.0) / s, qf - float2(10.0, 16.0) * (1.9 / unit), 0.46, 0.84, u));
    float occB = smoothstep(0.05, 0.7, layer(p + float2(-14.0, -22.0) / s, qm - float2(14.0, 22.0) * (1.25 / unit), 0.36, 0.78, u));

    float vert = clamp((p.y - u.box.y) / max(u.box.w, 1.0), 0.0, 1.0);
    float belly = smoothstep(0.25, 1.0, vert);

    float3 sun = float3(0.995, 0.99, 0.975);
    float3 cold = float3(0.815, 0.845, 0.885);

    float sb = smoothstep(-0.06, 0.5, dbL - db);
    float sm = smoothstep(-0.06, 0.5, dmL - dm);
    float sf = smoothstep(-0.06, 0.5, dfL - df);
    float pb = mix(0.9, 1.0, extinct(db, 2.6));
    float pm = mix(0.9, 1.0, extinct(dm, 2.6));
    float pf = mix(0.9, 1.0, extinct(df, 2.6));
    float rimF = smoothstep(0.02, 0.3, df - dfL) * (1.0 - extinct(df, 3.0)) * 0.06;
    float rimM = smoothstep(0.02, 0.3, dm - dmL) * (1.0 - extinct(dm, 3.0)) * 0.05;
    float3 cb = mix(sun, cold, clamp(sb * 0.5 + belly * 0.28 + occB * 0.16, 0.0, 0.7)) * pb * 0.965;
    float3 cm = mix(sun, cold, clamp(sm * 0.5 + belly * 0.2 * smoothstep(0.2, 1.0, dm) + occM * 0.14, 0.0, 0.65)) * pm * 0.985 + rimM;
    float3 cf = mix(sun, cold, clamp(sf * 0.45 + belly * 0.14 * smoothstep(0.2, 1.0, df), 0.0, 0.6)) * pf + rimF;
    float ab = extinct(db, 3.2);
    float am = extinct(dm, 3.0);
    float af = extinct(df, 2.8);

    float f = field(p, u);
    float near = smoothstep(0.45, 1.25, f) * (0.10 + 0.16 * fbm(q * 1.3 + float2(1.5)));
    float far = smoothstep(0.14, 0.9, f) * (0.04 + 0.12 * fbm(q * 0.6 + float2(t * 0.02)));
    float drop = smoothstep(0.35, 1.3, field(p - float2(0.0, 30.0 / s), u)) * u.shadow;

    float3 col = float3(0.0);
    float a = 0.0;
    over(col, a, float3(0.0), drop);
    over(col, a, float3(0.955, 0.965, 0.98), far);
    over(col, a, float3(0.965, 0.972, 0.985), near);
    over(col, a, cb, ab);
    over(col, a, cm, am);
    over(col, a, cf, af);

    if (u.sweep >= 0.0) {
        float margin = 140.0;
        float axis = (p.x - (u.box.x - margin)) / max(u.box.z + margin * 2.0, 1.0);
        float cross = (p.y - (u.box.y - 60.0)) / max(u.box.w + 120.0, 1.0);
        float tw = t * 0.8;
        float waveX = (sin(cross * 6.0 + tw * 1.3) * 0.020 + sin(cross * 13.0 - tw * 0.9 + 1.4) * 0.012 + sin(cross * 21.0 + tw * 1.7 + 2.6) * 0.006) * 0.55;
        float d = (axis - u.sweep) - waveX;
        float band = exp(-d * d * 18.0);
        float dh = -2.0 * d * 18.0 * band;
        float3 N = normalize(float3(-dh * 0.18, (dfL - df + dmL - dm) * 0.9, 1.0));
        float trail = pow(clamp(0.5 - d * 1.3, 0.0, 1.0), 2.5) * 0.30;
        float intensity = max(band * 0.95, trail);
        float hue = N.x * 0.45 + N.y * 0.30 + axis * 1.4 + cross * 0.35 + (df - dm) * 1.2 + t * 0.04;
        float3 rc = pal(hue, u);
        float3 V = float3(0.0, 0.0, 1.0);
        float3 Lk = normalize(float3(0.35, 0.55, 0.9));
        float3 H = normalize(Lk + V);
        float fresnel = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), 3.0);
        float spec = pow(clamp(dot(N, H), 0.0, 1.0), 80.0);
        float entry = mix(0.2, 1.0, 4.0 * u.sweep * (1.0 - u.sweep));
        float k = intensity * entry * u.sweepAlpha;
        float thick = smoothstep(0.1, 0.9, max(max(db, dm), df));
        col = mix(col, rc * (0.9 + 0.1 * thick), k * 0.6);
        col += (rc * fresnel * 0.22 + float3(spec) * 0.22) * band * entry * u.sweepAlpha * (0.4 + 0.6 * thick);
        a = max(a, k * 0.2 * smoothstep(0.1, 0.6, f));
    }

    float aa = a * u.alpha;
    return float4(col * aa, aa);
}

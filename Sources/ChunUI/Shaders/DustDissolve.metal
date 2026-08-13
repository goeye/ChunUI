//
//  DustDissolve.metal
//  Chat0IM
//
//  Telegram 式粒子消散管线（移植自 chat0-iOS DustEffect，两处升级）：
//  1. 粒子网格与像素解耦：分辨率由 Swift 侧决定，密度可控（原版每像素一粒子太重）
//  2. 初始化内核接收随机种子：每次消散的粒子飞散图样都不同
//

#include <metal_stdlib>
using namespace metal;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Loki 随机数发生器（Tausworthe 组合，GPU 侧确定性随机）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class DustLoki {
private:
    thread float seed;
    unsigned TausStep(const unsigned z, const int s1, const int s2, const int s3, const unsigned M) {
        unsigned b = (((z << s1) ^ z) >> s2);
        return (((z & M) << s3) ^ b);
    }

public:
    thread DustLoki(const unsigned seed1, const unsigned seed2 = 1, const unsigned seed3 = 1) {
        unsigned seed = seed1 * 1099087573UL;
        unsigned seedb = seed2 * 1099087573UL;
        unsigned seedc = seed3 * 1099087573UL;

        unsigned z1 = TausStep(seed, 13, 19, 12, 429496729UL);
        unsigned z2 = TausStep(seed, 2, 25, 4, 4294967288UL);
        unsigned z3 = TausStep(seed, 3, 11, 17, 429496280UL);
        unsigned z4 = (1664525 * seed + 1013904223UL);

        unsigned r1 = (z1 ^ z2 ^ z3 ^ z4 ^ seedb);
        z1 = TausStep(r1, 13, 19, 12, 429496729UL);
        z2 = TausStep(r1, 2, 25, 4, 4294967288UL);
        z3 = TausStep(r1, 3, 11, 17, 429496280UL);
        z4 = (1664525 * r1 + 1013904223UL);

        r1 = (z1 ^ z2 ^ z3 ^ z4 ^ seedc);
        z1 = TausStep(r1, 13, 19, 12, 429496729UL);
        z2 = TausStep(r1, 2, 25, 4, 4294967288UL);
        z3 = TausStep(r1, 3, 11, 17, 429496280UL);
        z4 = (1664525 * r1 + 1013904223UL);

        this->seed = (z1 ^ z2 ^ z3 ^ z4) * 2.3283064365387e-10;
    }

    thread float rand() {
        unsigned hashed_seed = this->seed * 1099087573UL;
        unsigned z1 = TausStep(hashed_seed, 13, 19, 12, 429496729UL);
        unsigned z2 = TausStep(hashed_seed, 2, 25, 4, 4294967288UL);
        unsigned z3 = TausStep(hashed_seed, 3, 11, 17, 429496280UL);
        unsigned z4 = (1664525 * hashed_seed + 1013904223UL);
        thread float old_seed = this->seed;
        this->seed = (z1 ^ z2 ^ z3 ^ z4) * 2.3283064365387e-10;
        return old_seed;
    }
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 数据结构
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct DustParticle {
    packed_float2 offsetFromBasePosition;
    packed_float2 velocity;
    float lifetime;
};

struct DustQuadVertexOut {
    float4 position [[position]];
    float2 uv;
    float alpha;
};

constant static float2 dustQuadVertices[6] = {
    float2(0.0, 0.0),
    float2(1.0, 0.0),
    float2(0.0, 1.0),
    float2(1.0, 0.0),
    float2(0.0, 1.0),
    float2(1.0, 1.0)
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 辅助函数
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

static float2 dustMapLocalToScreen(float4 rect, float2 size, float2 position) {
    return float2(rect.x + position.x / size.x * rect.z,
                  rect.y + position.y / size.y * rect.w);
}

/// 自上而下的消散波：fraction 为消散进度，t 为粒子行归一位置
static float dustEaseInValueAt(float fraction, float t) {
    float windowSize = 0.8;
    float windowPosition = (1.0 - fraction) * (-windowSize) + fraction * 1.0;
    float windowT = max(0.0, min(windowSize, t - windowPosition)) / windowSize;
    return 1.0 - windowT;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 计算内核
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

kernel void dustEffectInitializeParticle(
    device DustParticle *particles [[buffer(0)]],
    const device uint &seed [[buffer(1)]],
    uint gid [[thread_position_in_grid]]
) {
    DustLoki rng = DustLoki(gid, seed);

    DustParticle particle;
    particle.offsetFromBasePosition = packed_float2(0.0, 0.0);

    float direction = rng.rand() * (3.14159265 * 2.0);
    float velocity = (0.1 + rng.rand() * 0.1) * 840.0;
    particle.velocity = packed_float2(cos(direction) * velocity, sin(direction) * velocity);
    particle.lifetime = 0.4 + rng.rand() * 0.4;

    particles[gid] = particle;
}

kernel void dustEffectUpdateParticle(
    device DustParticle *particles [[buffer(0)]],
    const device uint2 &size [[buffer(1)]],
    const device float &phase [[buffer(2)]],
    const device float &timeStep [[buffer(3)]],
    uint gid [[thread_position_in_grid]]
) {
    uint count = size.x * size.y;
    if (gid >= count) { return; }

    constexpr float easeInDuration = 0.4;
    float effectFraction = max(0.0, min(easeInDuration, phase)) / easeInDuration;

    uint particleY = gid / size.x;
    float particleYFraction = 1.0 - (float(particleY) / float(size.y));
    float particleFraction = dustEaseInValueAt(effectFraction, particleYFraction);

    DustParticle particle = particles[gid];
    particle.offsetFromBasePosition += (particle.velocity * timeStep) * particleFraction;
    particle.velocity += float2(0.0, timeStep * 240.0) * particleFraction;
    particle.lifetime = max(0.0, particle.lifetime - timeStep * particleFraction);
    particles[gid] = particle;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 渲染管线
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vertex DustQuadVertexOut dustEffectVertex(
    const device float4 &rect [[buffer(0)]],
    const device float2 &size [[buffer(1)]],
    const device uint2 &particleResolution [[buffer(2)]],
    const device DustParticle *particles [[buffer(3)]],
    unsigned int vid [[vertex_id]],
    unsigned int particleId [[instance_id]]
) {
    DustQuadVertexOut out;

    float2 quadVertex = dustQuadVertices[vid];

    uint particleIndexX = particleId % particleResolution.x;
    uint particleIndexY = particleId / particleResolution.x;

    DustParticle particle = particles[particleId];

    float2 particleSize = size / float2(particleResolution);
    float2 topLeftPosition = float2(float(particleIndexX) * particleSize.x,
                                    float(particleIndexY) * particleSize.y);

    out.uv = (topLeftPosition + quadVertex * particleSize) / size;

    topLeftPosition += particle.offsetFromBasePosition;
    float2 position = topLeftPosition + quadVertex * particleSize;

    out.position = float4(dustMapLocalToScreen(rect, size, position), 0.0, 1.0);
    out.alpha = max(0.0, min(0.3, particle.lifetime) / 0.3);

    return out;
}

fragment half4 dustEffectFragment(
    DustQuadVertexOut in [[stage_in]],
    texture2d<half, access::sample> inTexture [[texture(0)]]
) {
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    half4 color = inTexture.sample(s, float2(in.uv.x, 1.0 - in.uv.y));
    return color * in.alpha;
}

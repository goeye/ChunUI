# Shaders/
> L2 | 父级: ../../../CLAUDE.md

Metal 着色器层：SPM 自动编译进 Bundle.module 的 default.metallib。

成员清单
CCShaders.swift: Swift 侧唯一取用门面（ShaderLibrary.bundle(.module)；禁 ShaderLibrary.default）
Aurora.metal: 极光 · GlimmSweep.metal: 扫光（citrus 余弦调色+虹彩+菲涅尔） · FractalTextures.metal: 九分形 halftone 点阵
DustDissolve.metal: 粒子消散 compute 管线 · MetaBalls.metal / Silk.metal / Beams.metal / Noise.metal / Sinebow.metal / card.metal / ColorBendsAurora.metal: 各特效片元

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md

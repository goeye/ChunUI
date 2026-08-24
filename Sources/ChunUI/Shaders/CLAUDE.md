# Shaders/
> L2 | 父级: ../../../CLAUDE.md

Metal 着色器层：SPM 自动编译进 Bundle.module 的 default.metallib。

成员清单
CCShaders.swift: Swift 侧唯一取用门面（ShaderLibrary.bundle(.module)；禁 ShaderLibrary.default）
Aurora.metal: 极光 · GlimmSweep.metal: 扫光（citrus 余弦调色+虹彩+菲涅尔） · FractalTextures.metal: 九分形 halftone 点阵
DustDissolve.metal: 粒子消散 compute 管线 · MetaBalls.metal / Silk.metal / Beams.metal / Noise.metal / Sinebow.metal / card.metal / ColorBendsAurora.metal: 各特效片元
CCGradientWaves.metal: 发言涟漪海面（ccGradientWavesVertex 全屏三角 + ccGradientWavesFragment 等离子体 raymarch **70 步**倒挂[40 步糊成雾]、原版参数基线抬振幅 3.4 + 能量调制、浪心轴色带（波谷 wave/波峰 crest）+ smoothstep 雾层级、**顶 1/3 限幅**（0.24→0.34 收零），预乘 alpha；经典管线专供 Effects/CCGradientWavesView 的 MTKView 渲染器，非 stitchable）

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md

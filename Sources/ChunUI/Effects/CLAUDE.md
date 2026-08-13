# Effects/
> L2 | 父级: ../../../CLAUDE.md

视觉特效层：shader 消费侧组件，全部经 CCShaders 取包内 Metal 库。

成员清单
CCAuroraLayer.swift: AI 工作态底部极光（相位累计器，暂停零帧更新；显式 public init）
GeneratingCover.swift: 「生成中」四层质感（中性底+实体色氤氲+7pt 呼吸点阵+对表白流光）
CCFractalFloor.swift: 九分形族点阵地板（Julia/Newton/Mandelbrot…，edge 贴顶/贴底渐隐）
CCSweepLight.swift: 转场扫光协调器（穿透覆盖窗 + GlimmSweep.metal）
ParticleDissolve.swift: 窗口级粒子消散（快照 + 独立 Metal 层 + 按需 DisplayLink）
HolographicCardEffects.swift: 全息卡片效果族
MetaBallsBackground.swift: 元球背景
SilkView.swift: 丝绸效果
BeamsView.swift: 光束效果
ColorBendsView.swift: 颜色弯曲
RandomNoiseShader.swift: 随机噪声
RainbowLineView.swift: 彩虹线条
AurorabackGround.swift: 极光背景（旧版氛围层）

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md

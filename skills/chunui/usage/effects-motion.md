# 特效与动效装配

## 入场动画范式（CCMotion · 禁止各页自写曲线）

```swift
@State private var shown = false

row.ccReveal(shown, index: i)        // 零过冲上浮入场（timingCurve 0.22,0.8,0.36,1 · 0.32s），index 错峰 0.07s
dot.ccWaveReveal(shown, index: i)    // spring 微过冲波浪（26pt 行程 + 0.96 微缩放），错峰 0.13s

.onAppear { shown = true }           // 列表/宫格入场一律用这两个
```

页面切换：`AnyTransition.ccPageRise`（新页微升 12pt 淡入 / 旧页原地淡出）。

## AI 工作态特效

```swift
CCAuroraLayer(visible: aiWorking)     // 底部极光（Metal）：visible=false 冻结相位零帧耗电
CCGeneratingCover()                   // 「生成中」四层质感：中性底+实体色氤氲+7pt 呼吸点阵+对表白流光
CCSweepLight.fire()                   // 全屏转场扫光（onboarding 步进、重大状态切换）
```

## 氛围底纹

```swift
CCFractalFloor(edge: .bottom, kind: .mandelbrot)   // 九分形点阵地板（.julia/.newton3/.burningShip/…）
FluidGradient(blobs: […], highlights: […], speed: 1)
MetaBallsBackground() / SilkView() / BeamsView() / ColorBendsView()
OrbView(configuration: OrbConfiguration())          // 拟物 AI 球
GridBackground()
```

## 骨架屏与扫光（替代一切 spinner）

```swift
CCSkeleton {                          // 骨架必须镜像真实布局，加载完原位换真身
    HStack {
        CCBone(height: 44, circle: true)
        VStack(alignment: .leading) { CCBone(width: 120); CCBoneText(lines: 2) }
    }
}
anyView.shimmer(active: isLoading)    // 扫光修饰符
```

## 文字动画

```swift
CCDesigin.CCTyperText("逐字打出", duration: 2)   // 打字机（一次性文本，不限行数）
CCStreamingText(streamingString)                // 流式（绑定实时增长字符串，AI 输出场景，带触觉）
```

## 删除的粒子消散

```swift
let box = DissolveFrameBox()
targetView.dissolveFrame(into: box)             // 取景
ParticleDissolve.run(rect: box.rect) { 删除动作() }   // 窗口级粒子飞散
```

## 性能纪律

- 循环动画一律 `TimelineView` 时刻取模，**禁 `repeatForever`**（后台积压补播炸帧）
- 常驻特效层必须支持「不可见即零帧」（CCAuroraLayer 的 visible 模式是范本）
- Metal shader 全部内置于包 bundle；**宿主自绘取 shader 函数一律经公开的 `CCShaders.xxx`，禁 `ShaderLibrary.default`**（主 bundle 无 metallib，直调即黑块）

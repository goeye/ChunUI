---
name: chunui
description: Build iOS apps with the ChunUI design system (Monochrome texture extracted from the production app Zinner/Chat0IM). Use when integrating ChunUI via SPM, theming with CCColors, using CC components (buttons/forms/cards/sheet/toast/alert/skeleton), Metal effects (aurora/fractal/generating/sweep), motion primitives (ccReveal/zoom transitions), or the UIKit×SwiftUI hybrid presentation architecture. Includes real production page sources as LEGO blueprints.
---

# ChunUI 开发技能

ChunUI 是从生产级 iOS 应用 Zinner（阿奇/Chat0IM）提取的 SwiftUI 设计系统。
**使命：让你用它搭积木，搭出 Chat0IM 同级别 UI 质感的产品。**

## 目录（按需深入）

| 文档 | 内容 |
|---|---|
| `usage/setup.md` | SPM 接入、一行换肤、宿主接线座、组件文案本地化、可选资产 |
| `usage/presentation.md` | UIKit×SwiftUI 混合架构：窗口分层、sheet 标准（脏态/zoom 转场）、toast/alert、相册相机 |
| `usage/effects-motion.md` | 入场动画范式、AI 工作态特效、氛围底纹、骨架屏、打字机/流式、粒子消散、性能纪律 |
| `components/reference.md` | 全组件逐类参考（令牌/按钮/表单/卡片/chrome/反馈/媒体/文本/图标） |
| `examples/` | **五个真实生产页面源码**——组件组合的积木图纸（README 有阅读法） |

## 架构一图流

```
UIWindow 层级:  主窗口(UINav+Hosting) → CCToastWindow(+1) → CCAlertWindow(+2) → Sweep 覆盖窗
呈现命令式:     AppHelper.presentSheet / showBottomAlert / CCToastCenter.show（禁 SwiftUI .sheet/.alert）
主题单向流:     ChunUI.configure(colors:strings:) → CCColors.current → Color.cc.* → 全组件
```

## 质感五铁律（违反即失真）

1. **唯一彩色**：页面上只有 `Color.cc.primary` 一个彩色，其余全灰阶语义色；功能色也从品牌色同轴选冷调
2. **三梯度字号**：只用 `Font.cc.sm(13)/base(17)/lg(24)`（+Bold）；文字统一 `.ccText(font:color:)`
3. **呈现走命令式**：sheet/alert/toast 全走 AppHelper/CCToastCenter，禁系统原生弹窗 API
4. **动效走令牌**：入场一律 `ccReveal/ccWaveReveal`，循环动画禁 `repeatForever`
5. **图标统一 PikaIcon**：1225 枚随包，禁散用 SF Symbols 当业务图标

## 快速上手（30 秒）

```swift
// 1. App 启动
var colors = CCColors.default
colors.primary = .hex("你的品牌色")
ChunUI.configure(colors: colors)

// 2. SceneDelegate
CCToastWindow.shared.attach(to: windowScene)
CCAlertWindow.shared.attach(to: windowScene)

// 3. 开搭
CCNeoButton("开始", variant: .primary, fullWidth: true) { await start() }
CCToastCenter.shared.show(.success, "已保存")
AppHelper.shared.presentSheet(.form) { EditView() }
```

## 常见坑

| 症状 | 解法 |
|---|---|
| shader 特效黑块 | 宿主自绘调了 `ShaderLibrary.xxx`（主 bundle 无 metallib，函数查找失败即渲染黑块）。一律改 `CCShaders.xxx`（包内库，public）。真实案例：Zinner 订阅卡分形纹理直调 `ShaderLibrary.fractalJulia` 迁包后全黑，改 `CCShaders.fractalJulia` 即愈 |
| 换肤不生效 | configure 必须先于首个视图创建；运行时换主题需触发根视图重建 |
| sheet 无脏态确认 | 内容视图缺 `@EnvironmentObject var ctx: CCEditSheetContext` 或未挂 `.ccEditSheetDirty` |
| toast 不显示 | 未 attach 窗口，或场景未 foregroundActive |
| 组件文案是英文 | 未覆写 CCStrings（usage/setup.md） |
| 图标空白 | 图标名不在 pika 集，用 `PikaIcon.Name.*` 常量防拼写 |

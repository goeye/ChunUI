---
name: chunui
description: Build iOS apps with the ChunUI design system (Monochrome texture from Zinner). Use when integrating ChunUI via SPM, theming with CCColors, using CC components (buttons/forms/cards/sheet/toast/alert/skeleton), Metal effects (aurora/fractal/generating/sweep), motion primitives (ccReveal/zoom transitions), or the UIKit×SwiftUI hybrid presentation architecture (AppHelper/window layering).
---

# ChunUI 开发技能

ChunUI 是从生产级 iOS 应用 Zinner（阿奇）提取的 SwiftUI 设计系统。本技能教你：混合架构如何运转、每个组件怎么用、特效动画怎么装配。

## 0. 接入与初始化（必读契约）

```swift
// Package.swift 或 Xcode Package Dependencies:
// https://github.com/liseami/ChunUI  (branch: main)

// App 启动时（AppDelegate.didFinishLaunching / @main init）——唯一初始化入口：
import ChunUI

var colors = CCColors.default            // Zinner 同款极致黑白粉
colors.primary = .hex("你的品牌色")        // 唯一彩色原则：只换这一个就够
ChunUI.configure(colors: colors)         // 全组件族即刻生效

// 可选接线座（宿主系统对接，全部静态注入，包零反向依赖）：
ChunUI.hapticsEnabled = true                          // 触觉总开关
ChunUI.defaultAvatarURL = "https://…/avatar.png"      // 等于此 URL 的头像视作缺省
ChunUI.sheetPresentHook = { host, name in Analytics.page(name) }  // sheet 呈现埋点
CCTrack.onTap = { Analytics.tap($0) }                 // 组件级点击埋点（按钮自动上报）
CCImageLoader.custom = { url, _ in AnyView(KFImage(url).resizable()) }  // 图片加载接管
CCImageLoader.urlNormalizer = { $0.replacingOccurrences(of: "旧域", with: "新域") }
AppHelper.toastRouteResolver = { .capsule }           // toast 路由策略（默认顶部胶囊）
```

**文案本地化**：组件内建文案（取消/保存/加载失败…）走 `CCStrings`，宿主用自己的本地化系统覆写：
```swift
var strings = CCStrings()
strings.cancel = String(localized: "action.cancel")
ChunUI.configure(colors: colors, strings: strings)
// 应用支持运行时切语言的话，语言变更后必须重新 configure 一次
```

**宿主可选资产**（放宿主 Assets 即自动启用，不放有兜底）：`avatar-default`（缺省头像）、`camera_bg`（相机皮革底）、CCEmptyState 的插图（按 CCEmptyKind rawValue 命名）。

## 1. 架构：UIKit × SwiftUI 混合范式

ChunUI 的呈现层不是纯 SwiftUI——它复刻了 Zinner 的窗口分层架构，这是质感的骨骼：

```
UIWindow 层级（自下而上）:
  主窗口          UINavigationController + UIHostingController(SwiftUI 页面)
  CCToastWindow   toast/上传进度（.alert+1 级；胶囊态触摸全透传）
  CCAlertWindow   沉底 Alert（.alert+2 级；无内容处 hitTest 穿透）
  Sweep 覆盖窗    CCSweepLight.fire() 时临时置顶，扫光完自动回收
```

**铁律**：
- sheet 一律命令式 `AppHelper.shared.presentSheet {}`，**禁止 SwiftUI `.sheet`**（原生 UISheetPresentationController 才有 detents/grabber/脏态下拉确认/zoom 转场）。
- alert 一律 `AppHelper.shared.showBottomAlert`，**禁止 UIAlertController 与 SwiftUI `.alert`**。
- toast 一律 `CCToastCenter.shared.show`，**禁止第三方 toast 库**。
- 包不持有宿主导航栈：`CCPresentationAnchor` 从 key window 就地发现呈现宿主，`CCNav.pop()` 就地发现导航栈。

窗口挂载：CCToastWindow/CCAlertWindow 在首次使用时自动创建（SceneDelegate 无需配置）。

## 2. 组件用法速查

### 按钮（自带触觉 + 埋点 + loading）
```swift
CCNeoButton("主操作", variant: .primary, fullWidth: true) { await submit() }  // async 自动转 loading
CCNeoButton("危险", variant: .danger, icon: "delete-dustbin01") { ... }
// 变体: .primary/.secondary/.ghost/.outline/.danger · 尺寸: .large/.medium/.small
// accent: 参数可临时覆色（如微信绿）
CCDesigin.GlassIconButton(icon: "settings-01") { }        // 正圆液态玻璃（iOS26 Liquid Glass/以下微拟物）
CCDesigin.CircleButton(icon: "arrow-left") { }
任意视图.softGlassStyle(.capsule)                          // 玻璃底修饰符（.circle/.capsule/.roundedRectangle(r)）
```

### 表单
```swift
CCDesigin.CCInput(placeholder: "昵称", text: $name)
CCDesigin.CCTextArea(placeholder: "备注", text: $memo)
CCDesigin.CCToggle(isOn: $on)
CCDesigin.CCCheckbox(isChecked: $checked, label: "同意协议")
CCNeoInput(placeholder: "微拟物输入", text: $text, icon: "search-default")
```

### 卡片与标签
```swift
CCAppleCard { 内容 }                       // 连续圆角+发丝边+三级软阴影（shadowLevel 1..3）
任意视图.appleCard(radius: 20)              // 修饰符版
VStack { rows }.ccGroupCard()              // 设置组卡片
CCCuteTag("128 人", icon: "user-love-heart")   // 统计胶囊
CCKeycapTag("BETA", color: .cc.success)        // 键帽标签
CCSettingRow(icon: "settings-01", title: "通用", trailing: .chevron)  // trailing: .chevron/.badge/.pro/.text()/.value()/.none
```

### Sheet 标准（原生 pageSheet 深度调参）
```swift
AppHelper.shared.presentSheet(.form)    { EditView() }     // 全高表单，tracksEdits 脏态下拉确认
AppHelper.shared.presentSheet(.half)    { PickerView() }   // 半高
AppHelper.shared.presentSheet(.compact(280)) { TipView() } // 定高
AppHelper.shared.presentSheet(.picker)  { PhotoPicker() }  // 贴底吞安全区
AppHelper.shared.dismissSheet()
// 脏态协议：sheet 内容拿 @EnvironmentObject var ctx: CCEditSheetContext，编辑后 ctx.isDirty = true
// zoom 锚点转场：源视图 .ccZoomSource(id:)，presentSheet(.form.zoom(from: id)) 即英雄转场
```

### Toast / Alert
```swift
CCToastCenter.shared.show(.success, "已保存")     // .info/.success/.warning/.error/.loading
CCToastCenter.shared.show(.loading, "上传中…")    // 常驻直到被下一条顶换
AppHelper.shared.showBottomAlert(
    title: "删除？", message: "不可恢复",
    actions: [CCAlertAction(title: "删除", role: .destructive)]  // 单 destructive 自动补取消
)
```

### 骨架屏与扫光（替代一切 spinner）
```swift
CCSkeleton {                                // 骨架必须镜像真实布局，加载完原位换真身
    HStack { CCBone(height: 44, circle: true); CCBoneText(lines: 2) }
}
任意视图.shimmer(active: isLoading)          // 扫光修饰符（TimelineView 取模，禁 repeatForever）
```

### 文字动画
```swift
CCDesigin.CCTyperText("逐字打出", duration: 2)        // 打字机（一次性文本）
CCStreamingText(streamingString)                     // 流式（绑定实时增长的字符串，AI 输出场景）
MarkdownText("**加粗** `code`", font: .cc.base)
```

## 3. 特效与动画装配

### 入场动画范式（CCMotion · 禁止各页自写曲线）
```swift
row.ccReveal(shown, index: i)        // 零过冲上浮入场，index 错峰 0.07s
dot.ccWaveReveal(shown, index: i)    // 微过冲波浪，错峰 0.13s
// shown 初始 false，onAppear 置 true；列表/宫格入场一律用这两个
```

### Metal 特效（全部从包 bundle 取 shader，无需任何配置）
```swift
CCAuroraLayer(visible: aiWorking)     // AI 工作态极光：visible=false 冻结相位零帧耗电
CCGeneratingCover()                   // 「生成中」呼吸点阵：铺在占位卡上
CCFractalFloor(edge: .bottom, kind: .mandelbrot)  // 九分形点阵地板（登录页/关于页氛围）
CCSweepLight.fire()                   // 全屏转场扫光（onboarding 步进、重大状态切换）
MetaBallsBackground() / SilkView() / BeamsView() / ColorBendsView()  // 氛围底
FluidGradient(blobs: [...], highlights: [...], speed: 1)
OrbView(configuration: OrbConfiguration())   // 拟物 AI 球
```

### 性能纪律
- 所有循环动画走 `TimelineView` 时刻取模，**禁 `repeatForever`**（后台积压补播会炸帧）。
- 极光/点阵这类常驻层必须支持「不可见即零帧」（CCAuroraLayer 的 visible 模式）。

## 4. 设计铁律（同质感的根）

1. **唯一彩色**：页面上只有 `Color.cc.primary` 一个彩色，其余全部灰阶语义色。功能色也从品牌色同轴选冷调（destructive 不用大红）。
2. **三梯度字号**：只用 `Font.cc.sm(13)/base(17)/lg(24)`（+Bold），禁第四个字号。
3. **文字统一写法**：`Text("…").ccText(font: .cc.base, color: .cc.foreground)`。
4. **间距令牌**：`CGFloat.cc.base(16)/sm(8)`，发丝线 `.cc.hairline(0.5)`。
5. **图标统一 PikaIcon**：`PikaIcon("search-default", size: 18, color: .cc.mutedForeground)`，1225 枚随包。

## 5. 常见坑

| 症状 | 原因与解法 |
|---|---|
| shader 特效黑屏 | 你在用 `ShaderLibrary.default`；包内特效已内置 CCShaders，宿主无需处理。自写 shader 才需要自己的 bundle |
| toast 不显示 | 场景未激活时调用；确保在 foregroundActive 后调用 |
| sheet 拿不到脏态确认 | 内容视图没写 `@EnvironmentObject var ctx: CCEditSheetContext` 或 config 用了 tracksEdits: false |
| 换肤不生效 | `configure` 必须在首个视图创建前调用；运行时换主题后需触发根视图重建 |
| 图标显示空白 | 图标名不在 pika 集；用 PikaIcon.Name.* 常量防拼写 |
| 组件文案是英文 | 没覆写 CCStrings；见第 0 节 |

## 6. 参考

- 组件画廊源码（每个组件的标准用法）：`Sources/ChunUIDemo/GalleryPages*.swift`
- 可运行示例 App：`Example/ChunUIGallery.xcodeproj`
- 架构文档树：各目录 `CLAUDE.md`（L1/L2 分形文档）

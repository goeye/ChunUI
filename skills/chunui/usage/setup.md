# 接入与初始化

## SPM 引入

```swift
// Xcode: File → Add Package Dependencies → https://github.com/liseami/ChunUI (branch: main)
// 或 Package.swift:
.package(url: "https://github.com/liseami/ChunUI", branch: "main")
```

iOS 18.6+。唯一第三方依赖 Pow（自动带入）。

## 一行换肤（App 启动首行，先于任何视图创建）

```swift
import ChunUI

var colors = CCColors.default            // Zinner 同款极致黑白粉
colors.primary = .hex("你的品牌色")        // 唯一彩色原则：通常只改这一个
colors.ring = colors.primary
ChunUI.configure(colors: colors)
```

`CCColors` 是 shadcn 同构语义调色板：background/card/panel/sidebarBg/muted/accent/border/destructive/success…
全组件经 `Color.cc.*` 只读取当前调色板，换肤即全家着装。

## 宿主接线座（全部静态注入，包零反向依赖）

```swift
ChunUI.hapticsResolver = { userPrefs.haptics }        // 触觉实时读用户设置（@AppStorage 直连）
ChunUI.defaultAvatarURL = "https://…/avatar.png"      // 等于此 URL 的头像视作缺省
ChunUI.sheetPresentHook = { host, name in … }         // sheet 呈现回调（host controller + 内容页名 → 埋点）
CCTrack.onTap = { Analytics.tap($0) }                 // 组件级点击埋点（按钮族自动上报）
CCImageLoader.custom = { url, role in                 // 网络图接管（如 Kingfisher）
    AnyView(KFImage(url).resizable())
}
CCImageLoader.urlNormalizer = { $0.replacing… }       // URL 归一（历史死域名重写）
AppHelper.toastRouteResolver = { .capsule }           // toast 路由策略（见 presentation.md）
```

## 组件文案本地化

组件内建文案（取消/保存/加载失败/相机权限…）走 `CCStrings`，宿主用自己的本地化系统覆写：

```swift
var strings = CCStrings()
strings.cancel = String(localized: "action.cancel")
strings.unsavedTitle = String(localized: "sheet.unsaved.title")
ChunUI.configure(colors: colors, strings: strings)
// 支持运行时切语言的应用：语言变更后必须重新 configure 一次
```

## 宿主可选资产（放 Assets 即启用，不放有兜底）

| 资产名 | 用途 | 缺失兜底 |
|---|---|---|
| `avatar-default` | 缺省头像铺满 | 灰底 SF 人形 |
| `camera_bg` | 相机皮革底纹 | 空 |
| CCEmptyKind rawValue 同名插图 | 空态插图 | 空 |

真实装配范例见宿主项目的 `ChunUIBridge.swift` 模式：所有定制收口在一个桥接文件，禁止散写。

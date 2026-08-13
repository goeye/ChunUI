# 呈现层：UIKit × SwiftUI 混合架构

这是 Zinner 质感的骨骼。呈现不走纯 SwiftUI，而是命令式 UIKit 承载 SwiftUI 内容：

```
UIWindow 层级（自下而上）:
  主窗口          UINavigationController + UIHostingController(SwiftUI 页面)
  CCToastWindow   toast / 上传进度（.alert+1；胶囊态触摸全透传）
  CCAlertWindow   沉底 Alert（.alert+2；无内容处 hitTest 穿透）
  Sweep 覆盖窗    CCSweepLight.fire() 临时置顶，扫光完自动回收
```

## 五条铁律

1. sheet 一律 `AppHelper.shared.presentSheet {}`——**禁 SwiftUI .sheet**（原生 detents/grabber/脏态确认/zoom 转场只有 UIKit 有）
2. alert 一律 `AppHelper.shared.showBottomAlert`——**禁 UIAlertController / SwiftUI .alert**
3. toast 一律 `CCToastCenter.shared.show`——**禁第三方 toast**
4. 包不持有宿主导航栈：`CCPresentationAnchor` 从 key window 就地发现，`CCNav.pop()` 就地返回
5. 窗口挂载：SceneDelegate 里 `CCToastWindow.shared.attach(to: scene)` / `CCAlertWindow.shared.attach(to: scene)`

## Sheet 标准

```swift
AppHelper.shared.presentSheet(.form)         { EditView() }   // 全高表单（默认脏态下拉确认）
AppHelper.shared.presentSheet(.half)         { Picker() }     // 半高
AppHelper.shared.presentSheet(.compact(280)) { Tip() }        // 定高
AppHelper.shared.presentSheet(.picker)       { PhotoPick() }  // 贴底吞安全区（选图/浏览器）
AppHelper.shared.dismissSheet()
```

**脏态协议**（编辑型 sheet 的灵魂）：

```swift
struct EditSheet: View {
    @EnvironmentObject var ctx: CCEditSheetContext   // presentSheet 自动注入
    var body: some View {
        content
            .ccEditSheetDirty(draft, baseline: original)   // 值不等 = 脏，下拉弹确认
            .ccEditSheetSave { await save() }              // 顶部 ✓ 的保存动作
    }
}
// 配套头部：CCEditSheetHeader(title: "编辑资料")——左标题右 X↔✓ 脏态切换
```

**Zoom 英雄转场**：

```swift
sourceCard.ccZoomSource(id: CCZoomID.myCard)                       // 源打锚
AppHelper.shared.presentSheet(.form.zoom(from: CCZoomID.myCard)) { Detail() }  // 即英雄转场
```

## Toast / Alert

```swift
CCToastCenter.shared.show(.success, "已保存")    // .info/.success/.warning/.error/.loading
CCToastCenter.shared.show(.loading, "上传中…")   // 常驻至被下一条顶换

AppHelper.shared.showBottomAlert(
    title: "删除？", message: "不可恢复",
    actions: [CCAlertAction(title: "删除", role: .destructive)]   // 单 destructive 自动补取消
)
```

toast 路由策略可注入（如「一级页面走头像气泡、其余走顶部胶囊」）：

```swift
AppHelper.toastRouteResolver = {
    guard 在一级页面 else { return .capsule }
    return .aqiBubble(anchor: CCToastCenter.shared.advisorAvatarAnchor)
}
```

## 相册 / 相机

```swift
AppHelper.shared.presentPHPicker { media in … }   // PHPicker 多选 → [PickedMedia]（图+视频合计上限 MediaPickLimit.maxPerSession）
AppHelper.shared.presentSheet(.picker) { SquareCropPicker { image in … } }  // 头像正方裁剪
```

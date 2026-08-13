# 案例源码：Zinner（Chat0IM）真实生产页面

这些不是玩具 demo——是 App Store 在售应用的真实页面源码，组件密度最高的五个。
**读法**：忽略业务类型（ProspectStore/MainViewModel/UserManager 等，替换成你的），专注组件组合方式、间距节奏、动效编排。这就是「搭积木搭出同级质感」的积木图纸。

| 文件 | 页面 | 学什么 |
|---|---|---|
| `ProfileView.swift` | 个人中心 | CCSettingRow + ccGroupCard 设置组、CCQuickAction 四宫格、页头范式、UserAvatar、分区节奏 |
| `DatesView.swift` | 时间线列表 | ccFloatingPageHeader + CCPageHeader（副标题槽+trailing 双钮）、CCEmptyState、行卡片 + ccReveal 错峰入场、Menu 过滤器 |
| `VipBuyView.swift` | 订阅收银台 | CCCardDeck 套餐轮转卡、CCNeoButton 主 CTA、价签排版、氛围底纹、法务行 |
| `ScreenshotAnalysisCard.swift` | AI 分析卡 | CCAppleCard + CCGeneratingCover 生成态、CCZoomID 英雄转场、presentPHPicker 选图、GlassIconButton、CCTiltedMediaStrip 概念 |
| `MainTabbar.swift` | 底部 tabbar | 平面 tab + 玻璃球混合布局、中文/非中文字号分档、锚点 frame 上报（气泡 toast 锚定）、税感触觉 |

注意：这些文件依赖各自 App 的业务层，**不能直接编译**；可编译的最小用例见 `Sources/ChunUIDemo/GalleryPages*.swift` 与 `Example/ChunUIGallery.xcodeproj`。

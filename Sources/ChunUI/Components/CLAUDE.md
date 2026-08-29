# Components/
> L2 | 父级: ../../../CLAUDE.md

CC 组件族：按钮/表单/卡片/呈现/媒体 40+ 件，全部主题驱动零业务。

成员清单
CCButtons.swift: 按钮族（GlassButton/MetalGlassButton/GlassIconButton/CircleButton/返回钮，Pow glow/shake 按压）；PinkGlassButtonStyle = Kumo 强调钮受光配方（1px 深一线 ring + 主色混 15% 白→主色受光渐变 + 顶部 1px 内高光混 30% 白 + shadow-xs，零光晕，颜色全由 primary token 推算）
CCNeoButton.swift: 微拟物按钮五变体×三尺寸（async loading + 显式 public init）+ CCNeoPressStyle/CCListRowPressStyle
CCNeoCards.swift: CCAppleCard 连续圆角三级软阴影卡 + CCNeoInput + CCCuteTag/CCKeycapTag 胶囊标签
CCForms.swift: CCInput/CCTextArea/CCToggle/CCCheckbox/CCDatePicker 表单族；CCToggle = Kumo Switch 形制（扁 squircle 轨道 40×20 + 满高正方滑块双层阴影 + 1px ring 开态深一线，150ms ease-out，热区补足 44pt）
CCTexts.swift: CCText/CCTyperText 打字机
CCImages.swift: CCWebImage 内建 URLCache 加载器（CCImageLoader.custom 可整体接管）+ UserAvatar + CCAvatarFallback（宿主资产优先 SF 兜底）
CCLayout.swift: SubViewHeader/PageHeader/CCNavibarWithRightBtn 布局件
CCCommon.swift: ICON 图标映射 + CCEmptyView 旧入口
CCEmptyState.swift: 统一缺省态（插图资产由宿主提供）
CCPageHeader.swift: 编辑气质页头（标题+副标题槽+trailing 槽）
CCFloatingChrome.swift: 页面 chrome 范式（CCChromeBacking 双向模糊承托 + ccFloatingPageHeader）
CCNativeSheet.swift: 原生 UISheetPresentationController 深度调参 + CCSheetConfig 公开预设 + CCPresentationAnchor 窗口发现（脏态下拉确认）
CCEditSheetChrome.swift: 编辑 sheet 统一 chrome（X↔✓ 脏态切换）
CCBottomAlert.swift: 沉底双胶囊 Alert（CCAlertCenter + CCAlertWindow 置顶窗）
CCToast.swift: Kumo 叠放 toast（CCToastCenter 多张栈：结果顶换 loading/展开冻结倒计时；CCToastView 叠放编舞：最新在前、旧张缩 0.1 上探 12pt 对齐前张尺寸正文淡出、点整叠展开成列表、限 3 张可见、曲线 cubic-bezier(0.22,1,0.36,1)；卡片 = 状态色圆徽 + 正文 + 关闭钮进度环[冻结同暂停] + 图标色 3.33s 渐变；CCToastWindow 触摸只在叠层命中区 capsuleHitRect/气泡态接管）+ CCAqiBubbleToast + CCKeyboardWatcher
CCUploadToast.swift: 上传进度胶囊（UploadProgressCenter 字节级进度）
CCAqiBubbleTail.swift: 气泡几何原子——AqiBubbleTail 右下尖尾 + CCSpeechBubbleShape（Laper tooltip 法：气泡与底部中央尖尾一条闭合路径，两肋凹弯 + 圆尖，fill/stroke 连续无接缝）
CCSplitFlapText.swift: 机场翻牌板（React Bits SplitFlapText 移植：暗瓦上下半分体 + 前翻折下/后翻落定两相 3D 翻页 + 中缝铰链；随机字符序列错拍翻入落定目标，可多词循环；Reduce Motion 直落）
CCSkeleton.swift: Kumo SkeletonLine 骨架屏（CCBone 每条自带独立扫光：随机时长 1.3–1.7s + 随机相位[负延迟等价]、前景 8% ease-in-out 高光，整片不同步闪；CCBoneText 行宽各自随机末行更短；CCSkeleton 语义容器）
CCCardDeck.swift: Tinder 式无限轮转卡组容器
CCChipFlow.swift: 换行流布局 Layout
CCSettingRow.swift: 设置行原子（CCSettingRow/CCProTag/CCQuickAction）
CCIllustrationTile.swift: 插图动作瓦片
CCRainbowBar.swift: 彩虹进度条（12 色异速交织，TimelineView 取模）
CCBannerLine.swift: 横幅线条
CCLeatherStyle.swift: 皮革质感
CCTrackSeam.swift: 埋点依赖倒置座（CCTrack.onTap + .ccTrackTap）
CCZoomTransition.swift: UIKit Zoom 英雄转场基建（锚点注册表 + 装配工厂）
CCVideo.swift: 视频缩略/查看器（跟手拖拽回落）
CCCameraPicker.swift: 系统相机命令式出口（AppHelper.presentCamera → UIImage；无相机返回 false），与 CCPHPicker 并列
CCPHPicker.swift: 系统相册命令式出口（PHPicker → [PickedMedia]，出口挂 AppHelper）
PhotoSlector.swift: 照片选择器（选图时间记忆 CCPhotoSelectMemory）
SquareCropPicker.swift: 系统选图+正方裁剪
CCCamera.swift: 相机组件（权限文案走 CCStrings）
Camera/: 相机子系统（CameraViewModel/CameraPreviewView/FilteredCameraPreview/CameraFilter）
InAppBrowser.swift: 应用内浏览器（WKWebView + 玻璃关闭钮）
StreamingText.swift: 流式打字文本
ImageStackCarousel.swift: 图片堆叠轮播
GridBackground.swift: 网格背景
VideoBackground.swift: 视频背景
DisplayLinkView.swift: CADisplayLink 帧同步视图
ThinLine.swift: 细线分隔符

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md

# Components/
> L2 | 父级: ../../../CLAUDE.md

CC 组件族：按钮/表单/卡片/呈现/媒体 40+ 件，全部主题驱动零业务。

成员清单
CCButtons.swift: 玻璃按钮族（GlassButton/MetalGlassButton/GlassIconButton/CircleButton/返回钮，Pow glow/shake 按压）
CCNeoButton.swift: 微拟物按钮五变体×三尺寸（async loading + 显式 public init）+ CCNeoPressStyle/CCListRowPressStyle
CCNeoCards.swift: CCAppleCard 连续圆角三级软阴影卡 + CCNeoInput + CCCuteTag/CCKeycapTag 胶囊标签
CCForms.swift: CCInput/CCTextArea/CCToggle/CCCheckbox/CCDatePicker 表单族
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
CCToast.swift: 单槽玻璃胶囊 toast（CCToastCenter + CCToastWindow + 气泡路由可注入）+ CCKeyboardWatcher
CCUploadToast.swift: 上传进度胶囊（UploadProgressCenter 字节级进度）
CCAqiBubbleTail.swift: 气泡右下尖尾几何原子
CCSkeleton.swift: 扫光骨架屏（CCBone/CCBoneText/CCSkeleton 时钟取模扫光）
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

//
//  CCCamera.swift
//  YUI
//
//  拟物美食相机主视图
//

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - CCCamera

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCCamera: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = CCCameraViewModel()
    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false
    @State private var dialEntrySpinAngle: Double = 0 // 入场旋转角度
    @State private var dialEntryAnimationDone = false // 入场动画完成标记
    private let onCapture: (UIImage) -> Void
    private let onDismiss: (() -> Void)?

    public init(onCapture: @escaping (UIImage) -> Void, onDismiss: (() -> Void)? = nil) {
        self.onCapture = onCapture
        self.onDismiss = onDismiss
    }

    public var body: some View {
        GeometryReader { geo in
            let viewfinderWidth = geo.size.width - 32
            let viewfinderHeight = viewfinderWidth * 4 / 3
            let spacing: CGFloat = 20 // 三模块统一间距

            ZStack {
                leatherBackground

                VStack(spacing: spacing) {
                    // 第一行：关闭按钮（右对齐）
                    HStack {
                        Spacer()
                        metalCloseButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                    // 第二行：视频预览流
                    viewfinder.frame(width: viewfinderWidth, height: viewfinderHeight)

                    // 第三行：操作按钮
                    controlPanel
                }
            }
        }

        .onAppear {
            vm.startSession()
            startDialEntryAnimation()
        }
        .onDisappear { vm.stopSession() }
        .onChange(of: vm.capturedImage) { _, img in
            guard let img else { return }
            vm.capturedImage = nil
            onCapture(img)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // MARK: - 皮革背景 (平铺模式，不撑开布局)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var leatherBackground: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color.cc.primary.opacity(0.3), Color.cc.secondary.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image("camera_bg")
                    .resizable(resizingMode: .tile)
                    .opacity(0.5)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // MARK: - 取景框

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var viewfinder: some View {
        GeometryReader { geo in
            ZStack {
                if vm.permissionDenied {
                    permissionDeniedView
                } else {
                    // 实时滤镜预览 (Metal 渲染)
                    FilteredCameraPreview(
                        session: vm.session,
                        filter: $vm.currentFilter
                    )
                    // 胶片效果覆盖层 (颗粒 + 暗角)
                    FilmSimulationOverlay(filter: vm.currentFilter)
                    cameraBadge
                    focusIndicator
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.cc.shadow.opacity(0.2), lineWidth: 3)
            }
            .shadow(color: Color.cc.shadow.opacity(0.2), radius: 12, y: 6)
            .contentShape(Rectangle())
            .onTapGesture { location in
                // 转换为归一化坐标
                let normalizedPoint = CGPoint(
                    x: location.x / geo.size.width,
                    y: location.y / geo.size.height
                )
                focusTap(at: normalizedPoint, in: geo.size)
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // MARK: - 金属关闭按钮 (旋钮同款风格)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var metalCloseButton: some View {
        CCDesigin.CCButton {
            if let onDismiss { onDismiss() } else { dismiss() }
            AppHelper.shared.mada(.light)
        } label: {
            ZStack {
                // 外壳
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "f0f0f0"), Color(hex: "d0d0d0")],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 44)
                    .shadow(color: .cc.shadow.opacity(0.2), radius: 4, y: 2)

                // 金属纹理
                Circle()
                    .fill(AngularGradient(colors: [Color(hex: "c0c0c0"), Color(hex: "e8e8e8"),
                                                   Color(hex: "a8a8a8"), Color(hex: "d8d8d8")],
                                          center: .center))
                    .frame(width: 40, height: 40)

                // 中心 + X 图标
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "f8f8f8"), Color(hex: "e0e0e0")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                    .shadow(color: .cc.shadow.opacity(0.1), radius: 1, y: 1)
                    .overlay {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "666666"))
                    }
            }
        }
    }

    private func focusTap(at point: CGPoint, in size: CGSize) {
        vm.focus(at: point)
        AppHelper.shared.mada(.light)

        // 显示对焦框
        withAnimation(.easeOut(duration: 0.15)) {
            focusPoint = CGPoint(x: point.x * size.width, y: point.y * size.height)
            showFocusIndicator = true
        }

        // 收缩动画后隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.2)) {
                showFocusIndicator = false
            }
        }
    }

    private var focusIndicator: some View {
        Group {
            if showFocusIndicator, let point = focusPoint {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.cc.primary, lineWidth: 1.5)
                    .frame(width: 70, height: 70)
                    .position(point)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var cameraBadge: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                // 焦段 (等宽数字)
                Text(vm.currentZoomLabel)
                    .font(.cc.mono(10))
                    .foregroundStyle(Color.cc.secondary)
                    .tracking(1)

                // 分隔符
                Rectangle()
                    .fill(Color.cc.secondary.opacity(0.5))
                    .frame(width: 1, height: 10)

                // 滤镜 (等宽数字)
                Text(vm.currentFilter.displayName)
                    .font(.cc.mono(10))
                    .foregroundStyle(Color.cc.secondary)
                    .tracking(2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.cc.overlay.opacity(0.5)).blur(radius: 0.5))
            .padding(.bottom, 16)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.currentZoomLabel)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.currentFilter)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 镜头盖 (权限被拒绝时显示)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var permissionDeniedView: some View {
        GeometryReader { geo in
            let capSize = min(geo.size.width, geo.size.height) * 0.7

            ZStack {
                // 深色背景
                Color(hex: "1a1a1a")

                // ━━━ 镜头盖主体 ━━━
                ZStack {
                    // 外圈金属环
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4a4a4a"), Color(hex: "2a2a2a"), Color(hex: "3a3a3a")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: capSize, height: capSize)
                        .shadow(color: .cc.shadow.opacity(0.5), radius: 10, y: 5)

                    // 内圈金属纹理
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color(hex: "3a3a3a"),
                                    Color(hex: "5a5a5a"),
                                    Color(hex: "2a2a2a"),
                                    Color(hex: "4a4a4a"),
                                    Color(hex: "3a3a3a")
                                ],
                                center: .center
                            )
                        )
                        .frame(width: capSize - 16, height: capSize - 16)

                    // 中心凹陷区域
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "1a1a1a"), Color(hex: "2a2a2a")],
                                center: .center,
                                startRadius: 0,
                                endRadius: capSize * 0.3
                            )
                        )
                        .frame(width: capSize * 0.6, height: capSize * 0.6)

                    // 内容区域
                    VStack(spacing: 12) {
                        // 提示文字
                        Text(CCStrings.current.cameraPermissionTitle)
                            .ccText(font: .cc.subheadlineBold , color: Color(hex: "999999"))
                            .multilineTextAlignment(.center)

                        Text(CCStrings.current.cameraPermissionSubtitle)
                            .ccText(font: .cc.footnote , color: Color(hex: "666666"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        // 前往设置按钮
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 12, weight: .medium))
                                Text(CCStrings.current.openSettings)
                                    .font(.cc.smBold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.cc.primary)
                            )
                        }
                        .padding(.top, 8)
                    }
                    .frame(width: capSize * 0.55)
                }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // MARK: - 控制面板 (钝角三角形布局)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var controlPanel: some View {
        HStack(spacing: 0) {
            dial(value: vm.currentZoomLabel, count: vm.availableCameraCount, index: vm.currentZoomIndex) {
                vm.cycleZoomLevel()
            }
            .offset(y: -40)
            .frame(maxWidth: .infinity)

            shutterButton

            dial(value: vm.currentFilter.shortName, count: CameraFilter.allCases.count,
                 index: CameraFilter.allCases.firstIndex(of: vm.currentFilter) ?? 0) {
                vm.cycleFilter()
            }
            .offset(y: -40)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .frame(maxHeight: .infinity)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // MARK: - 旋钮入场动画

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func startDialEntryAnimation() {
        // 初始角度：高速旋转起点
        dialEntrySpinAngle = 1080 // 起始时旋转 3 圈

        // 第一阶段：高速旋转 1 秒 (线性动画模拟匀速转动)
        withAnimation(.linear(duration: 1.0)) {
            dialEntrySpinAngle = 360 // 旋转到还剩 1 圈
        }

        // 第二阶段：1秒后自然落定 (带阻尼的弹簧动画)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                dialEntrySpinAngle = 0
                dialEntryAnimationDone = true
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // MARK: - 金属旋钮 (带丝滑动画)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func dial(value: String, count: Int, index: Int, action: @escaping () -> Void) -> some View {
        let baseAngle = -Double(index) * 360.0 / Double(max(count, 1))

        return CCDesigin.CCButton {
            action()
            AppHelper.shared.mada(.light)
        } label: {
            ZStack {
                // 外壳
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "f0f0f0"), Color(hex: "d0d0d0")],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 72, height: 72)
                    .shadow(color: .cc.shadow.opacity(0.2), radius: 5, y: 3)

                // 金属纹理 + 刻度 (整体旋转)
                ZStack {
                    Circle()
                        .fill(AngularGradient(colors: [Color(hex: "c0c0c0"), Color(hex: "e8e8e8"),
                                                       Color(hex: "a8a8a8"), Color(hex: "d8d8d8")],
                                              center: .center))
                        .frame(width: 66, height: 66)

                    // 刻度线
                    ForEach(0 ..< count, id: \.self) { i in
                        Rectangle()
                            .fill(i == 0 ? Color.cc.primary : Color(hex: "666666"))
                            .frame(width: i == 0 ? 3 : 2, height: 9)
                            .offset(y: -27)
                            .rotationEffect(.degrees(Double(i) * 360.0 / Double(max(count, 1))))
                    }
                }
                .rotationEffect(.degrees(dialEntrySpinAngle)) // 入场旋转
                .rotationEffect(.degrees(baseAngle)) // 选项切换旋转
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)

                // 中心
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "f8f8f8"), Color(hex: "e0e0e0")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                    .shadow(color: .cc.shadow.opacity(0.1), radius: 2, y: 1)
                    .overlay {
                        Text(value)
                            .font(.cc.smBold)
                            .foregroundStyle(Color.cc.primary)
                            .animation(.none, value: value)
                    }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // MARK: - 快门按钮 (能量球)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var shutterOrbConfig: OrbConfiguration {
        OrbConfiguration(
            backgroundColors: [
                Color(hex: "D4A574"), // 焦糖棕
                Color(hex: "E8B4B8"), // 玫瑰粉
                Color(hex: "C9A86C") // 暖金棕
            ],
            glowColor: Color(hex: "FFF5EE"), // 贝壳白
            particleColor: Color(hex: "FFE4E1"), // 薄雾玫瑰
            coreGlowIntensity: 0.8,
            showBackground: true,
            showWavyBlobs: true,
            showParticles: true,
            showGlowEffects: true,
            showShadow: true,
            speed: 45
        )
    }

    private var shutterButton: some View {
        CCDesigin.CCButton {
            vm.capturePhoto()
            AppHelper.shared.mada(.medium)
        } label: {
            ZStack {
                // 金属外环
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "e8e8e8"), Color(hex: "b0b0b0")],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 92, height: 92)
                    .shadow(color: .cc.shadow.opacity(0.25), radius: 8, y: 4)

                // 深色衬底
                Circle()
                    .fill(Color(hex: "1a1a1a"))
                    .frame(width: 84, height: 84)

                // 能量球
                OrbView(configuration: shutterOrbConfig)
                    .frame(width: 76, height: 76)
            }
        }
    }
}

#Preview {
    CCCamera { _ in }
}

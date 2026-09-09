#if canImport(UIKit)
//
//  ParticleDissolve.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 DesignSystem/Shader/DustDissolve.metal 的 dustEffect* 内核/顶点/片元函数、Metal/MetalKit、UIKit 窗口层级、SwiftUI onGeometryChange
 * [OUTPUT]: 对外提供 ParticleDissolve.run(rect:onStarted:) 窗口级 Telegram 式粒子消散、DissolveFrameBox / DissolveFrameStore 取景容器、View.dissolveFrame 取景修饰符
 * [POS]: DesignSystem/Effects 的删除动效基座，被文档树/推荐回复/消息/待办/日程五个删除落点共用；移植自 chat0-iOS DustEffect，改为按需 CADisplayLink + 粒子数上限 + 随机种子
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Metal
import MetalKit
import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 对外入口：窗口级消散协调器
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Telegram 式粒子消散。快照取自 key window（系统菜单/弹窗在独立 window，不会污染取景），
/// 粒子层挂在 window 顶端独立存活，源视图删除后动画照常收尾。
@MainActor
public enum ParticleDissolve {

    private static var overlay: DustOverlayView?

    /// 对窗口坐标 rect 区域播放消散。onStarted 在粒子接管画面后调用，此刻删数据最稳。
    public static func run(rect: CGRect, onStarted: (() -> Void)? = nil) {
        guard !UIAccessibility.isReduceMotionEnabled,
              rect.width > 1, rect.height > 1,
              let window = keyWindow(),
              let image = snapshot(window: window, rect: rect)
        else {
            onStarted?()
            return
        }

        let host: DustOverlayView
        if let overlay {
            host = overlay
        } else {
            let view = DustOverlayView(frame: window.bounds)
            view.onBecameEmpty = { [weak view] in
                view?.removeFromSuperview()
                if overlay === view { overlay = nil }
            }
            window.addSubview(view)
            overlay = view
            host = view
        }
        window.bringSubviewToFront(host)
        host.frame = window.bounds
        host.addDissolve(frame: rect, image: image)

        onStarted?()
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    /// 裁切 key window 当前画面到目标区域（afterScreenUpdates: false 直接读现存表面，开销最小）
    private static func snapshot(window: UIWindow, rect: CGRect) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(bounds: rect, format: format)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SwiftUI 取景：引用盒避开滚动期 @State 反复失效
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 单视图取景盒：引用语义，几何更新不触发 SwiftUI 重渲染
public final class DissolveFrameBox {
    public var rect: CGRect = .zero

    public init() {}
}

/// 多行取景仓：列表场景按 id 存行 frame，同样零失效
public final class DissolveFrameStore {
    var frames: [String: CGRect] = [:]
}

extension View {
    /// 持续记录视图的窗口坐标 frame 到取景盒
    public func dissolveFrame(into box: DissolveFrameBox) -> some View {
        onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { box.rect = $0 }
    }

    /// 持续记录视图的窗口坐标 frame 到取景仓
    public func dissolveFrame(id: String, into store: DissolveFrameStore) -> some View {
        onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { store.frames[id] = $0 }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 承载视图（穿透触摸，空了自毁）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private final class DustOverlayView: UIView {
    var onBecameEmpty: (() -> Void)?
    private var dustLayer: DustDissolveLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func addDissolve(frame: CGRect, image: UIImage) {
        if dustLayer == nil {
            let layer = DustDissolveLayer()
            layer.frame = bounds
            layer.becameEmpty = { [weak self] in
                self?.dustLayer?.removeFromSuperlayer()
                self?.dustLayer = nil
                self?.onBecameEmpty?()
            }
            self.layer.addSublayer(layer)
            dustLayer = layer
        }
        dustLayer?.frame = bounds
        dustLayer?.addItem(frame: frame, image: image)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Metal 粒子层（compute 更新 + instanced quad 渲染）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private final class DustDissolveLayer: CALayer {

    private final class Item {
        let frame: CGRect
        let texture: MTLTexture?
        let particleResolution: SIMD2<UInt32>
        let particleCount: Int
        var phase: Float = 0
        var particleBuffer: MTLBuffer?
        var particleBufferIsInitialized = false

        init?(frame: CGRect, image: UIImage, device: MTLDevice) {
            self.frame = frame

            guard let cgImage = image.cgImage else { return nil }
            let loader = MTKTextureLoader(device: device)
            self.texture = try? loader.newTexture(cgImage: cgImage, options: [
                .SRGB: false,
                .generateMipmaps: false,
            ])

            // 每 pt 一粒子，上限 6 万：超限按比例降密度，视觉无损、内存可控
            var cols = max(1, Int(frame.width))
            var rows = max(1, Int(frame.height))
            let maxCount = 60_000
            if cols * rows > maxCount {
                let shrink = (Double(maxCount) / Double(cols * rows)).squareRoot()
                cols = max(1, Int(Double(cols) * shrink))
                rows = max(1, Int(Double(rows) * shrink))
            }
            self.particleResolution = SIMD2<UInt32>(UInt32(cols), UInt32(rows))
            self.particleCount = cols * rows
        }
    }

    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var renderPipeline: MTLRenderPipelineState?
    private var initializePipeline: MTLComputePipelineState?
    private var updatePipeline: MTLComputePipelineState?

    private var metalLayer: CAMetalLayer?
    private var items: [Item] = []
    private var displayLink: CADisplayLink?
    private var lastUpdateTimestamp: CFTimeInterval?

    var animationSpeed: Float = 1.0
    var becameEmpty: (() -> Void)?

    override init() {
        super.init()
        isOpaque = false
        setupMetal()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        setupMetal()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        displayLink?.invalidate()
    }

    // ━━━ 装配 ━━━

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = try? device.makeDefaultLibrary(bundle: .module) else { return }
        self.device = device
        commandQueue = device.makeCommandQueue()

        let metal = CAMetalLayer()
        metal.device = device
        metal.pixelFormat = .bgra8Unorm
        metal.framebufferOnly = true
        metal.isOpaque = false
        metal.maximumDrawableCount = 2
        metal.presentsWithTransaction = false
        metal.allowsNextDrawableTimeout = true
        addSublayer(metal)
        metalLayer = metal

        do {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "dustEffectVertex")
            descriptor.fragmentFunction = library.makeFunction(name: "dustEffectFragment")
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = .add
            descriptor.colorAttachments[0].alphaBlendOperation = .add
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
            renderPipeline = try device.makeRenderPipelineState(descriptor: descriptor)

            if let fn = library.makeFunction(name: "dustEffectInitializeParticle") {
                initializePipeline = try device.makeComputePipelineState(function: fn)
            }
            if let fn = library.makeFunction(name: "dustEffectUpdateParticle") {
                updatePipeline = try device.makeComputePipelineState(function: fn)
            }
        } catch {
            renderPipeline = nil
        }
    }

    // ━━━ 入队 ━━━

    func addItem(frame: CGRect, image: UIImage) {
        guard let device, renderPipeline != nil,
              let item = Item(frame: frame, image: image, device: device) else {
            becameEmpty?()
            return
        }
        // packed_float2 ×2 + float = 20 字节/粒子
        item.particleBuffer = device.makeBuffer(length: item.particleCount * 20, options: .storageModeShared)
        items.append(item)
        startDisplayLinkIfNeeded()
    }

    // ━━━ 帧驱动（按需 CADisplayLink，空了即拆） ━━━

    private func startDisplayLinkIfNeeded() {
        guard displayLink == nil else { return }
        let proxy = DisplayLinkProxy(target: self)
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        lastUpdateTimestamp = nil
    }

    fileprivate func step() {
        let timestamp = CACurrentMediaTime()
        let delta: CFTimeInterval
        if let last = lastUpdateTimestamp {
            let raw = timestamp - last
            delta = (raw <= 0.001 || raw >= 0.2) ? (1.0 / 60.0) : raw
        } else {
            delta = 0
        }
        lastUpdateTimestamp = timestamp

        for index in (0 ..< items.count).reversed() {
            items[index].phase += Float(delta) * animationSpeed
            if items[index].phase >= 2.0 {
                items[index].particleBuffer = nil
                items.remove(at: index)
            }
        }

        if items.isEmpty {
            stopDisplayLink()
            becameEmpty?()
            return
        }

        performCompute(timeStep: Float(delta))
        render()
    }

    private func performCompute(timeStep: Float) {
        guard let commandQueue,
              let initializePipeline,
              let updatePipeline,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }

        for item in items {
            guard let particleBuffer = item.particleBuffer else { continue }

            let threadgroupSize = MTLSize(width: 32, height: 1, depth: 1)
            let threadgroupCount = MTLSize(
                width: (item.particleCount + threadgroupSize.width - 1) / threadgroupSize.width,
                height: 1,
                depth: 1
            )

            if !item.particleBufferIsInitialized {
                item.particleBufferIsInitialized = true
                encoder.setComputePipelineState(initializePipeline)
                encoder.setBuffer(particleBuffer, offset: 0, index: 0)
                var seed = UInt32.random(in: 1 ... .max)
                encoder.setBytes(&seed, length: MemoryLayout<UInt32>.size, index: 1)
                encoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
            }

            if timeStep > 0 {
                encoder.setComputePipelineState(updatePipeline)
                encoder.setBuffer(particleBuffer, offset: 0, index: 0)
                var resolution = item.particleResolution
                encoder.setBytes(&resolution, length: MemoryLayout<SIMD2<UInt32>>.size, index: 1)
                var phase = item.phase
                encoder.setBytes(&phase, length: MemoryLayout<Float>.size, index: 2)
                var step = timeStep * 2.0
                encoder.setBytes(&step, length: MemoryLayout<Float>.size, index: 3)
                encoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
            }
        }

        encoder.endEncoding()
        commandBuffer.commit()
    }

    private func render() {
        guard let metalLayer,
              let renderPipeline,
              let commandQueue,
              bounds.width > 0, bounds.height > 0 else { return }

        if metalLayer.drawableSize.width == 0 || metalLayer.drawableSize.height == 0 {
            let scale = UIScreen.cc_active.scale
            metalLayer.drawableSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        }

        guard let drawable = metalLayer.nextDrawable() else { return }

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        pass.colorAttachments[0].storeAction = .store

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }

        encoder.setRenderPipelineState(renderPipeline)

        for item in items {
            guard let particleBuffer = item.particleBuffer, let texture = item.texture else { continue }

            // 翻转到 Metal 的左下原点，再映射 NDC
            var itemFrame = item.frame
            itemFrame.origin.y = bounds.height - itemFrame.maxY

            var rect = SIMD4<Float>(
                Float(itemFrame.minX / bounds.width * 2.0 - 1.0),
                Float(itemFrame.minY / bounds.height * 2.0 - 1.0),
                Float(itemFrame.width / bounds.width * 2.0),
                Float(itemFrame.height / bounds.height * 2.0)
            )
            encoder.setVertexBytes(&rect, length: MemoryLayout<SIMD4<Float>>.size, index: 0)

            var size = SIMD2<Float>(Float(itemFrame.width), Float(itemFrame.height))
            encoder.setVertexBytes(&size, length: MemoryLayout<SIMD2<Float>>.size, index: 1)

            var resolution = item.particleResolution
            encoder.setVertexBytes(&resolution, length: MemoryLayout<SIMD2<UInt32>>.size, index: 2)

            encoder.setVertexBuffer(particleBuffer, offset: 0, index: 3)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: item.particleCount)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        metalLayer?.frame = bounds
        if let metalLayer {
            let scale = UIScreen.cc_active.scale
            metalLayer.drawableSize = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        }
    }
}

/// CADisplayLink 强持有 target，用代理断开对层的保留环
private final class DisplayLinkProxy {
    weak var target: DustDissolveLayer?
    public init(target: DustDissolveLayer) { self.target = target }
    @objc func tick() { target?.step() }
}

#endif

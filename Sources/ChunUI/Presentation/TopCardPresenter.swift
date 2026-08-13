import SwiftUI
import UIKit
import OSLog

/// 用于在顶级窗口展示SwiftUI视图卡片的控制器
public final class TopCardPresenter : NSObject{
    
    // MARK: - 单例实例
    
    /// 共享实例
    public static let shared = TopCardPresenter()
    
    // MARK: - 私有属性
    
    /// 卡片数据模型，存储每个卡片的相关数据
    private struct CardData {
        let window: UIWindow
        let viewController: UIViewController
        let backgroundView: UIView
        let cardView: UIView
        let initialCenter: CGPoint
        var isTopmost: Bool // 是否是最顶层卡片
    }
    
    /// 卡片堆栈
    private var cards: [CardData] = []
    
    // 日志记录器
    private let logger = Logger(subsystem: "com.cc.YUI", category: "TopCardPresenter")
    
    // MARK: - 初始化方法
    
    private override init() {}
    
    // MARK: - 公共方法
    
    /// 在屏幕中央展示SwiftUI卡片
    /// - Parameters:
    ///   - view: 要展示的SwiftUI视图
    ///   - animated: 是否使用动画效果，默认为true
    ///   - backgroundColor: 背景颜色，默认为半透明黑色
    ///   - isUserInteractionEnabled: 用户是否可以通过点击背景关闭卡片，默认为true
    ///   - completion: 展示完成后的回调
    @MainActor
    public func presentCard<Content: View>(
        view: Content,
        animated: Bool = true,
        backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.5),
        isUserInteractionEnabled: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        logger.debug("开始展示卡片，当前卡片数量: \(self.cards.count)")
        
        // 将之前的所有卡片标记为非顶层
        for i in 0..<cards.count {
            var cardData = cards[i]
            cardData.isTopmost = false
            cards[i] = cardData
        }
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        logger.debug("创建HostingController成功")
        
        // 创建背景视图
        let bgView = UIView()
        bgView.backgroundColor = backgroundColor
        bgView.alpha = 0.3
        logger.debug("创建背景视图成功，背景色: \(backgroundColor)")
        
        if isUserInteractionEnabled {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
            bgView.addGestureRecognizer(tapGesture)
            logger.debug("添加背景点击手势成功")
        }
        
        // 获取当前活跃的场景和窗口
        guard let windowScene = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .first as? UIWindowScene else {
            logger.error("无法获取活跃的UIWindowScene")
            return
        }
        
        logger.debug("获取到活跃的WindowScene: \(windowScene)")
        
        // 创建新窗口，使用当前活跃的windowScene
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 100 + CGFloat(cards.count) // 每个新卡片增加层级
        window.backgroundColor = .clear
        logger.debug("创建窗口成功，windowLevel: \(window.windowLevel.rawValue)")
        
        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .clear
        window.rootViewController = containerVC
        logger.debug("设置容器控制器成功")
        
        // 添加背景视图和卡片视图
        containerVC.view.addSubview(bgView)
        containerVC.addChild(hostingController)
        containerVC.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: containerVC)
        logger.debug("添加子视图和控制器成功")
        
        // 配置布局
        bgView.frame = containerVC.view.bounds
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.centerXAnchor.constraint(equalTo: containerVC.view.centerXAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: containerVC.view.centerYAnchor),
            hostingController.view.widthAnchor.constraint(lessThanOrEqualTo: containerVC.view.widthAnchor, multiplier: 0.9),
            hostingController.view.heightAnchor.constraint(lessThanOrEqualTo: containerVC.view.heightAnchor, multiplier: 0.9)
        ])
        logger.debug("设置约束成功")
        
        // 添加手势识别器到卡片视图
        addGesturesToCardView(hostingController.view)
        
        // 添加到卡片堆栈
        let initialCenter = CGPoint(
            x: containerVC.view.bounds.midX,
            y: containerVC.view.bounds.midY
        )
        
        let cardData = CardData(
            window: window, 
            viewController: hostingController,
            backgroundView: bgView,
            cardView: hostingController.view,
            initialCenter: initialCenter,
            isTopmost: true
        )
        cards.append(cardData)
        logger.debug("将卡片添加到堆栈，当前卡片数量: \(self.cards.count)")
        
        // 显示窗口
        window.isHidden = false
        window.makeKeyAndVisible()
        logger.debug("窗口已设为可见：isHidden=\(window.isHidden), isKeyWindow=\(window.isKeyWindow)")
        
        // 应用动画
        if animated {
            hostingController.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            hostingController.view.alpha = 0
            
            logger.debug("开始执行展示动画")
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.3,
                options: .curveEaseOut,
                animations: {
                    bgView.alpha = 1
                    hostingController.view.alpha = 1
                    hostingController.view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05) // 过量变化
                    self.logger.debug("展示动画执行中 - 第一阶段")
                },
                completion: { _ in
                    UIView.animate(withDuration: 0.15, animations: {
                        hostingController.view.transform = .identity // 恢复正常大小
                        self.logger.debug("展示动画执行中 - 第二阶段")
                    }, completion: { _ in
                        self.logger.debug("展示动画完成")
                        completion?()
                    })
                }
            )
        } else {
            bgView.alpha = 1
            logger.debug("不使用动画，直接显示")
            completion?()
        }
    }
    
    /// 关闭当前展示的卡片
    /// - Parameters:
    ///   - animated: 是否使用动画效果，默认为true
    ///   - completion: 关闭完成后的回调
    @MainActor
    public func dismissCard(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !cards.isEmpty else {
            logger.warning("没有找到当前展示的卡片，可能已被关闭")
            completion?()
            return
        }
        
        dismissCard(at: cards.count - 1, animated: animated, completion: completion)
    }
    
    /// 关闭指定索引的卡片
    /// - Parameters:
    ///   - index: 要关闭的卡片索引
    ///   - animated: 是否使用动画效果
    ///   - completion: 关闭完成后的回调
    @MainActor
    public func dismissCard(at index: Int, animated: Bool = true, completion: (() -> Void)? = nil) {
        logger.debug("准备关闭索引为 \(index) 的卡片")
        
        guard index >= 0 && index < cards.count else {
            logger.warning("无效的卡片索引: \(index)")
            completion?()
            return
        }
        
        let cardData = cards[index]
        
        if animated {
            logger.debug("开始执行关闭动画")
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                cardData.backgroundView.alpha = 0
                cardData.cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                cardData.cardView.alpha = 0
                self.logger.debug("关闭动画执行中")
            }, completion: { _ in
                self.logger.debug("关闭动画完成")
                self.cleanupCard(at: index)
                
                // 如果还有卡片，将最上层的卡片标记为顶层
                if !self.cards.isEmpty {
                    var topCardData = self.cards[self.cards.count - 1]
                    topCardData.isTopmost = true
                    self.cards[self.cards.count - 1] = topCardData
                }
                
                completion?()
            })
        } else {
            logger.debug("不使用动画，直接关闭")
            cleanupCard(at: index)
            
            // 如果还有卡片，将最上层的卡片标记为顶层
            if !cards.isEmpty {
                var topCardData = cards[cards.count - 1]
                topCardData.isTopmost = true
                cards[cards.count - 1] = topCardData
            }
            
            completion?()
        }
    }
    
    /// 关闭所有卡片
    /// - Parameters:
    ///   - animated: 是否使用动画效果
    ///   - completion: 关闭完成后的回调
    @MainActor
    public func dismissAllCards(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !cards.isEmpty else {
            logger.warning("没有卡片需要关闭")
            completion?()
            return
        }
        
        let group = DispatchGroup()
        
        // 从后往前关闭每个卡片
        for i in (0..<cards.count).reversed() {
            group.enter()
            dismissCard(at: i, animated: animated) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.logger.debug("所有卡片已关闭")
            completion?()
        }
    }
    
    // MARK: - 私有方法
    
    /// 添加手势到卡片视图
    private func addGesturesToCardView(_ view: UIView) {
        // 添加拖动手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
        
        // 添加点击手势（点击卡片内部但不触发其他交互时关闭）
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        logger.debug("已添加拖动和点击手势到卡片视图")
    }
    
    @objc @MainActor private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // 只有顶层卡片响应手势
        guard let cardView = gesture.view,
              let cardIndex = getCardIndex(for: cardView),
              cards[cardIndex].isTopmost else {
            return
        }
        
        let cardData = cards[cardIndex]
        let translation = gesture.translation(in: cardView.superview)
        let velocity = gesture.velocity(in: cardView.superview)
        
        switch gesture.state {
        case .began:
            // 记录开始拖动
            logger.debug("开始拖动卡片，索引: \(cardIndex)")
            // 重置手势的初始平移量，确保每次新的拖动从零开始计算
            gesture.setTranslation(.zero, in: cardView.superview)
            
        case .changed:
            // 允许向下拖动，不限制距离
            if translation.y > 0 {
                // 设置卡片位置，只跟随Y轴移动
                cardView.center = CGPoint(
                    x: cardData.initialCenter.x,
                    y: cardData.initialCenter.y + translation.y
                )
                
                // 随着拖动距离增加，计算透明度和缩放比例
                let screenHeight = UIScreen.cc_active.bounds.height
                let dragPercentage = min(translation.y / (screenHeight / 4), 1.0)
                
                // 减小背景视图透明度
                cardData.backgroundView.alpha = 1.0 - dragPercentage * 0.7
                
                // 轻微缩小
                let scale = max(1.0 - dragPercentage * 0.1, 0.9)
                cardView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            
        case .ended, .cancelled:
            // 仅在松手时判断是否满足关闭条件
            let dismissThreshold = cardView.frame.height * 0.3
            
            if velocity.y > 300 || translation.y > dismissThreshold {
                // 满足关闭条件，淡出消失
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    // 不改变位置和transform，只改变透明度
                    cardView.alpha = 0
                    cardData.backgroundView.alpha = 0
                }, completion: { _ in
                    self.dismissCard(at: cardIndex, animated: false)
                })
                logger.debug("松手时满足关闭条件，卡片淡出消失")
            } else {
                // 否则，恢复卡片位置
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.2, options: .curveEaseOut, animations: {
                    cardView.center = cardData.initialCenter
                    cardView.transform = .identity
                    cardData.backgroundView.alpha = 1.0
                }, completion: nil)
                logger.debug("松手时未满足关闭条件，恢复卡片位置")
            }
            
        default:
            break
        }
    }
    
    @objc @MainActor private func cardTapped(_ gesture: UITapGestureRecognizer) {
        // 只有顶层卡片响应手势
        guard let cardView = gesture.view,
              let cardIndex = getCardIndex(for: cardView),
              cards[cardIndex].isTopmost,
              gesture.state == .ended else {
            return
        }

        logger.debug("卡片被点击，准备关闭")
        dismissCard(at: cardIndex)
    }
    
    @objc @MainActor private func backgroundTapped() {
        // 只关闭最顶层的卡片
        guard !cards.isEmpty else { return }
        
        logger.debug("背景被点击，准备关闭卡片")
        dismissCard()
    }
    
    private func cleanupCard(at index: Int) {
        guard index >= 0 && index < cards.count else {
            logger.warning("尝试清理无效索引的卡片: \(index)")
            return
        }
        
        logger.debug("开始清理索引为 \(index) 的卡片资源")
        
        let cardData = cards[index]
        
        if let hostingController = cardData.viewController as? UIHostingController<AnyView> {
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
        } else {
            cardData.viewController.view.removeFromSuperview()
            cardData.viewController.removeFromParent()
        }
        logger.debug("移除了卡片控制器")
        
        cardData.backgroundView.removeFromSuperview()
        cardData.window.isHidden = true
        logger.debug("隐藏窗口并移除背景视图")
        
        // 从数组中移除卡片数据
        cards.remove(at: index)
    }
    
    private func getCardIndex(for view: UIView) -> Int? {
        return cards.firstIndex { $0.cardView === view }
    }
    
    private func printWindowsInfo() {
        logger.debug("打印所有窗口信息:")
        UIApplication.shared.connectedScenes.forEach { scene in
            if let windowScene = scene as? UIWindowScene {
                logger.debug("场景: \(windowScene), 激活状态: \(windowScene.activationState.rawValue)")
                windowScene.windows.forEach { window in
                    logger.debug("窗口: \(window), 层级: \(window.windowLevel.rawValue), 可见: \(window.isHidden ? "否" : "是"), isKey: \(window.isKeyWindow ? "是" : "否")")
                }
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TopCardPresenter: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 对于卡片上的点击手势，只有当用户点击的是卡片本身而不是其内部控件时才允许响应
        if let tapGesture = gestureRecognizer as? UITapGestureRecognizer,
           let cardView = tapGesture.view,
           let cardIndex = getCardIndex(for: cardView) {
            return touch.view === cardView && cards[cardIndex].isTopmost
        }
        return false
    }
}

// MARK: - 预览
#if DEBUG

public struct DemoCardView: View {
    var onClose: () -> Void
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("这是一个演示卡片")
                .ccText(font: .cc.body , color: .cc.foreground)
                .padding(.top)
            
            Text("这个卡片将在屏幕中央展示，并且会在顶级窗口上")
                .multilineTextAlignment(.center)
                .ccText(font: .cc.callout , color: .cc.mutedForeground)
                .padding(.horizontal)
            
            CCDesigin.CCButton {
                onClose()
            } label: {
                Text("关闭卡片")
            }
            .padding(.bottom)
        }
        .frame(width: 300)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

public struct TopCardPreviewView: View {
    @State private var showCard = false
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("顶级卡片演示")
                .font(.title)
                .padding(.top)
            
            Button("显示卡片") {
                Task { @MainActor in
                    showCard = true
                    TopCardPresenter.shared.presentCard(
                        view: DemoCardView(onClose: {
                            Task { @MainActor in
                                TopCardPresenter.shared.dismissCard()
                            }
                        })
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("显示多个卡片") {
                Task { @MainActor in
                    showCard = true
                    TopCardPresenter.shared.presentCard(
                        view: DemoCardView(onClose: {
                            Task { @MainActor in
                                TopCardPresenter.shared.dismissCard()
                            }
                        })
                    )
                    
                    // 延迟显示第二个卡片
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        TopCardPresenter.shared.presentCard(
                            view: DemoCardView(onClose: {
                                Task { @MainActor in
                                    TopCardPresenter.shared.dismissCard()
                                }
                            })
                        )
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("关闭所有卡片") {
                Task { @MainActor in
                    TopCardPresenter.shared.dismissAllCards()
                }
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    TopCardPreviewView()
}

#endif 

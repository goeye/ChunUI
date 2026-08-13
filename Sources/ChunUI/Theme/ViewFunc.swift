//
//  ViewFunc.swift
//  YUI
//
//  Created by 赵翔宇 on 2025/2/17.
//

import Foundation
import SwiftUI

// MARK: - 视图高度测量

public struct ViewHeightPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
  
}

// MARK: - View 扩展方法

extension View {
    // MARK: - 文字样式

    /// 快速应用 CC 设计系统的文字样式
    /// 此方法将同时设置字体和颜色，使文字风格统一
    ///
    /// - Parameters:
    ///   - font: CCFont 中定义的字体
    ///   - color: CC 设计系统中定义的语义色
    ///
    /// 使用示例：
    /// ```
    /// Text("标题文本")
    ///     .ccText(font: .cc.hero, color: .cc.foreground)
    ///
    /// Text("次要文本")
    ///     .ccText(font: .cc.callout, color: .cc.mutedForeground)
    /// ```
    public func ccText(font: Font, color: Color) -> some View {
        self.font(font).foregroundStyle(color)
    }

    /// ccText 渐变重载 - 支持 LinearGradient 等 ShapeStyle
    ///
    /// - Parameters:
    ///   - font: 字体
    ///   - style: 任意 ShapeStyle (LinearGradient, AngularGradient 等)
    ///
    /// 使用示例：
    /// ```
    /// Text("$99")
    ///     .ccText(font: .cc.hero, style: goldGradient)
    /// ```
    public func ccText<S: ShapeStyle>(font: Font, style: S) -> some View {
        self.font(font).foregroundStyle(style)
    }

    // MARK: - 数字样式

    /// 快速应用 CC 设计系统的数字样式（系统等宽字体）
    /// 专用于：统计数据、价格、计数、百分比等数字展示
    ///
    /// - Parameters:
    ///   - size: 字号 (常用尺寸: 28/24/20/18/16/14/12)
    ///   - color: CC 设计系统中定义的语义色
    ///
    /// 使用示例：
    /// ```
    /// Text("1,234")
    ///     .ccNumber(size: 20, color: .cc.foreground)
    ///
    /// Text("99%")
    ///     .ccNumber(size: 16, color: .cc.primary)
    /// ```
    public func ccNumber(size: CGFloat, color: Color) -> some View {
        self.font(.cc.mono(size)).foregroundStyle(color)
    }

    // MARK: - 条件渲染

    /// 根据条件决定是否显示视图
    /// - Parameter show: 控制视图是否显示的布尔值
    /// - Returns: 如果 show 为 true 则显示视图，否则显示 EmptyView
    public func `if`(_ show: Bool) -> some View {
        Group {
            if show {
                self
            } else {
                EmptyView()
            }
        }
    }

    /// 条件变换：满足条件时应用 transform，否则保持原样
    /// - Parameters:
    ///   - condition: 控制是否应用变换的条件
    ///   - transform: 满足条件时对视图应用的变换
    /// - Returns: 变换后的视图或原视图
    @ViewBuilder
    public func when<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // MARK: - 占位效果

    /// 为视图添加占位效果
    /// 包括红色遮罩和闪烁动画效果
    /// - Returns: 带有占位效果的视图
    public func isPlaceholder(_ show: Bool = true) -> some View {
        Group {
            if show {
                self
                    .redacted(reason: .placeholder)
                    .shimmer()
            } else {
                self
            }
        }
    }

    // MARK: - 键盘控制

    /// 自动打开键盘
    /// - Returns: 自动打开键盘的视图
    public func autoOpenKeyboard() -> some View {
        self.modifier(AutoOpenKeyed())
    }

    /// 高性能死页面
    public func deadView() -> some View {
        self.equatable(by: true)
            .allowsHitTesting(false)
    }

    // MARK: - 延迟显示

    /// 延迟显示视图
    /// - Parameters:
    ///   - sec: 延迟显示的秒数
    ///   - transition: 显示时的过渡动画，默认为淡入效果
    /// - Returns: 延迟显示的视图
    public func showAfter(_ sec: Double, transition: AnyTransition = .opacity) -> some View {
        self.modifier(ShowAfterSecs(sec: sec, transition: transition))
    }

    // MARK: - 静态视图

    /// 将视图设置为静态视图
    /// 禁用交互并优化性能
    /// - Returns: 静态视图
    public func isStaticView() -> some View {
        return self.equatable(by: true)
            .allowsHitTesting(false)
    }

    // MARK: - 文本标签

    /// 将视图转换为文本标签样式
    /// - Parameters:
    ///   - textcolor: 文本颜色
    ///   - backColor: 背景颜色
    /// - Returns: 标签样式的视图
    public func isTextTag(_ textcolor: Color, backColor: Color) -> some View {
        self
            .ccText(font: .cc.captionBold , color: textcolor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(backColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// 获取视图的实际高度并执行回调
    /// 使用 PreferenceKey 系统进行高效的高度测量
    /// - Parameter completion: 高度变化时的回调闭包
    /// - Returns: 带有高度测量功能的视图
    public func getViewHeight(_ completion: @MainActor @escaping (CGFloat) -> Void) -> some View {
        self
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ViewHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            )
            .onPreferenceChange(ViewHeightPreferenceKey.self) { height in
                completion(height)
            }
    }

    public func addTopAndButtonBlur(top: CGFloat = 46, bottom: CGFloat = 90) -> some View {
        self
            .overlay(alignment: .top) {
                VariableBlurView(maxBlurRadius: 8, direction: .blurredTopClearBottom, startOffset: 0.2)
                    .frame(height: top)
                    .ignoresSafeArea()
            }
            .overlay(alignment: .bottom) {
                VariableBlurView(maxBlurRadius: 8, direction: .blurredBottomClearTop, startOffset: 0.2)
                    .ignoresSafeArea()
                    .frame(height: bottom)
            }
    }

    public func isCCMainScrollView() -> some View {
        self
            .scrollIndicators(.hidden, axes: .vertical)
            .background(Color.cc.background)
            .addTopAndButtonBlur(top: 90, bottom: 46)
    }

    public func addCloseBtn(at: Alignment = .topTrailing) -> some View {
        self
            .overlay(alignment: at) {
                CCDesigin.CircleButton(icon: "arrow-down") {
                    AppHelper.shared.dismissSheet()
                }
                .padding(.all, 16)
            }
    }

}



// MARK: - 预览示例

#Preview {
    VStack(spacing: 20) {
        Text("主标题示例")
            .ccText(font: .cc.hero , color: .cc.foreground)

        Text("副标题示例")
            .ccText(font: .cc.title1 , color: .cc.mutedForeground)

        Text("正文内容示例")
            .ccText(font: .cc.body , color: .cc.mutedForeground)

        Text("小字提示示例")
            .ccText(font: .cc.footnote , color: .cc.mutedForeground)
    }
    .padding()
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 局部等价渲染原语（SwiftUIX equatable(by:) 的包内替身）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCEquatableBox<Value: Equatable, Content: View>: View, Equatable {
    let value: Value
    let content: Content
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.value == rhs.value }
    public var body: some View { content }
}

extension View {
    /// 按给定值判等跳过 diff：值不变则子树不重算（静态装饰层专用）
    public func equatable<V: Equatable>(by value: V) -> some View {
        CCEquatableBox(value: value, content: self)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 键盘 / 延时呈现修饰符（迁自宿主 ViewModifiers）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct AutoOpenKeyed: ViewModifier {
    @FocusState private var isFocused: Bool

    public func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
    }
}

public struct ShowAfterSecs: ViewModifier {
    public var sec: Double = 0
    public var transition: AnyTransition
    @State private var show: Bool = false
    public init(sec: Double, transition: AnyTransition = .opacity) {
        self.sec = sec
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        if show {
            content
                .transition(transition)
                .animation(.smooth, value: show)
        } else {
            Color.clear.frame(width: 1, height: 1)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + sec) {
                        self.show = true
                    }
                }
        }
    }
}

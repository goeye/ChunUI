/**
 * [INPUT]: 依赖 UIScreen.displayCornerRadius
 * [OUTPUT]: 对外提供 CCSheetChrome.floatingShape(edgeInset:) / unevenPath——沉底 Alert 非对称圆角
 * [POS]: DesignSystem/Theme 的浮动卡片外形；业务 bottom sheet 已迁 AppHelper.presentSheet / CCNativeSheet
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

public enum CCSheetChrome {
    /// 下角 = 硬件屏圆角（Alert 贴屏底时）
    public static var bottomCornerRadius: CGFloat {
        let r = UIScreen.cc_active.displayCornerRadius
        return r > 0 ? r : 44
    }

    /// 上角收小（Alert 顶沿）；业务 sheet 圆角由 UISheetPresentationController.preferredCornerRadius 管
    public static var topCornerRadius: CGFloat { min(14, bottomCornerRadius * 0.28) }

    public static var cornerRadius: CGFloat { bottomCornerRadius }

    /// 卡片内缩 padding 后，下角与屏圆角同心
    public static func insetBottomRadius(padding: CGFloat) -> CGFloat {
        max(16, bottomCornerRadius - padding)
    }

    /// 沉底 Alert 外形；edgeInset>0 时下角同心内缩（8pt 浮空铁律）
    public static func floatingShape(edgeInset: CGFloat = 0) -> UnevenRoundedRectangle {
        let bottom = edgeInset > 0
            ? insetBottomRadius(padding: edgeInset)
            : bottomCornerRadius
        let top = min(14, bottom * 0.28)
        return UnevenRoundedRectangle(
            topLeadingRadius: top,
            bottomLeadingRadius: bottom,
            bottomTrailingRadius: bottom,
            topTrailingRadius: top,
            style: .continuous
        )
    }

    /// UIKit 非对称圆角路径（Alert 等）
    public static func unevenPath(in bounds: CGRect) -> UIBezierPath {
        let tl = topCornerRadius
        let tr = topCornerRadius
        let bl = bottomCornerRadius
        let br = bottomCornerRadius
        let path = UIBezierPath()
        let minX = bounds.minX
        let minY = bounds.minY
        let maxX = bounds.maxX
        let maxY = bounds.maxY

        path.move(to: CGPoint(x: minX + tl, y: minY))
        path.addLine(to: CGPoint(x: maxX - tr, y: minY))
        path.addQuadCurve(to: CGPoint(x: maxX, y: minY + tr), controlPoint: CGPoint(x: maxX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: maxY - br))
        path.addQuadCurve(to: CGPoint(x: maxX - br, y: maxY), controlPoint: CGPoint(x: maxX, y: maxY))
        path.addLine(to: CGPoint(x: minX + bl, y: maxY))
        path.addQuadCurve(to: CGPoint(x: minX, y: maxY - bl), controlPoint: CGPoint(x: minX, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: minY + tl))
        path.addQuadCurve(to: CGPoint(x: minX + tl, y: minY), controlPoint: CGPoint(x: minX, y: minY))
        path.close()
        return path
    }
}

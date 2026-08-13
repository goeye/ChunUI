//
//  CGAffineTransform+Extensions.swift
//  Chat0IM
//

import CoreGraphics

extension CGAffineTransform {
    /// Basic transform that combines scaling and translation
    public static func transform(from frameA: CGRect, to frameB: CGRect) -> Self {
        let scaleT = Self.makeScale(from: frameA, to: frameB)
        let translation = Self.makeTranslation(from: frameA, to: frameB)
        return scaleT.concatenating(translation)
    }

    /// Calculates the translation needed to move from center of `frameA` to center of `frameB`
    static func makeTranslation(from frameA: CGRect, to frameB: CGRect) -> Self {
        let centerA = CGPoint(x: frameA.midX, y: frameA.midY)
        let centerB = CGPoint(x: frameB.midX, y: frameB.midY)
        return CGAffineTransform(
            translationX: centerB.x - centerA.x,
            y: centerB.y - centerA.y
        )
    }

    /// Calculates the scale factor needed to make `frameA` match `frameB`'s size
    static func makeScale(from frameA: CGRect, to frameB: CGRect) -> Self {
        let scaleX = frameB.width / frameA.width
        let scaleY = frameB.height / frameA.height
        return CGAffineTransform(scaleX: scaleX, y: scaleY)
    }

    /// Transform with aspect fill
    public static func transform(parent: CGRect,
                          suchThatChild child: CGRect,
                          aspectFills targetRect: CGRect) -> Self
    {
        let childRatio = child.width / child.height
        let rectRatio = targetRect.width / targetRect.height

        let scaleX = targetRect.width / child.width
        let scaleY = targetRect.height / child.height
        let scaleFactor = rectRatio < childRatio ? scaleY : scaleX

        let offsetX = targetRect.midX - parent.midX
        let offsetY = targetRect.midY - parent.midY
        let centerOffsetX = (parent.midX - child.midX) * scaleFactor
        let centerOffsetY = (parent.midY - child.midY) * scaleFactor

        let translateX = offsetX + centerOffsetX
        let translateY = offsetY + centerOffsetY

        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let translateTransform = CGAffineTransform(translationX: translateX, y: translateY)

        return scaleTransform.concatenating(translateTransform)
    }

    /// Transform a frame into another frame. Assumes they're the same aspect ratio.
    public static func transform(originalFrame: CGRect,
                          toTargetFrame targetFrame: CGRect) -> Self
    {
        let scaleFactor = targetFrame.width / originalFrame.width

        let offsetX = targetFrame.midX - originalFrame.midX
        let offsetY = targetFrame.midY - originalFrame.midY

        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let translateTransform = CGAffineTransform(translationX: offsetX, y: offsetY)

        return scaleTransform.concatenating(translateTransform)
    }
}

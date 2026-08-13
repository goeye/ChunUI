//
//  SquareCropPicker.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 UIKit UIImagePickerController（iOS 内置选图 + 方形裁剪 UI）
 * [OUTPUT]: 对外提供 SquareCropPicker（UIViewControllerRepresentable：相册选图 → 系统内置正方形裁剪 → 回调 editedImage）
 * [POS]: DesignSystem/Compents 的头像选图原子，被 ProfileEditView / ProspectEditSheet / AddProspectSheet 头像流消费；头像域一律经此获得 1:1 裁剪图
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SquareCropPicker（系统选图 + 内置方形裁剪一步到位）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct SquareCropPicker: UIViewControllerRepresentable {
    var onPicked: (UIImage) -> Void

    public init(onPicked: @escaping (UIImage) -> Void) {
        self.onPicked = onPicked
    }

    @Environment(\.dismiss) private var dismiss

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true   // iOS 内置正方形裁剪步骤
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: SquareCropPicker

        public init(_ parent: SquareCropPicker) {
            self.parent = parent
        }

        public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // 裁剪产物优先；极端情况下回退原图
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            parent.dismiss()
            if let image {
                parent.onPicked(image)
            }
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

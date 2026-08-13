/**
 * [INPUT]: 依赖本包 Shaders 目录的 .metal 着色器（SPM 自动编译进 Bundle.module 的 default.metallib）
 * [OUTPUT]: 对外提供 CCShaders —— 包内 shader 函数唯一取用口
 * [POS]: Shaders 的 Swift 侧门面；包内组件禁止直用 ShaderLibrary.default（那指向宿主 main bundle）
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
import SwiftUI

/// 包内 Metal 库（dynamic member 取函数：CCShaders.aurora(...)）；公开给宿主——
/// 宿主自绘用包内 shader（如订阅卡分形纹理）必须经此取函数，禁 ShaderLibrary.default（主 bundle 无 metallib 会黑块）
nonisolated public let CCShaders = ShaderLibrary.bundle(.module)

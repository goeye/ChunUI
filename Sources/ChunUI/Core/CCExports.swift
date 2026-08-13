/**
 * [INPUT]: 系统框架 SwiftUI/UIKit/Combine/Foundation/QuartzCore
 * [OUTPUT]: 模块级隐式导入（与宿主 Chat0IM AppDelegate 同款范式，仅限系统框架）
 * [POS]: Core 的导入基座；包内文件免写系统 import，第三方库禁止出现在此
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
@_exported import Combine
@_exported import Foundation
@_exported import QuartzCore
@_exported import SwiftUI
@_exported import UIKit

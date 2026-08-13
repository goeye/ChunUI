//
//  CCColorAccessor+YUI.swift
//  YUI
//
//  YUI 业务语义颜色扩展
//

/**
 * [INPUT]: CCColorAccessor (来自 CCDesignSystem)
 * [OUTPUT]: 营养素图表专用语义色
 * [POS]: DesignSystem/Utils - 业务颜色别名
 *
 * [PROTOCOL]:
 * 1. 基于 CCDesignSystem 的 chart1-5 提供 YUI 业务语义别名
 * 2. chartCarbs = chart1 (绿色/碳水)
 * 3. chartProtein = chart2 (粉色/蛋白质)
 * 4. chartFat = chart3 (红色/脂肪)
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 营养素图表色 (YUI 业务语义)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public nonisolated extension CCColorAccessor {

    /// 碳水化合物 - 绿色 (chart1)
    var chartCarbs: Color { chart1 }

    /// 蛋白质 - 粉色 (chart2)
    var chartProtein: Color { chart2 }

    /// 脂肪 - 红色 (chart3)
    var chartFat: Color { chart3 }

    /// 深色卡片静音前景
    var darkCardMutedForeground: Color {
        Color.white.opacity(0.6)
    }

    /// 深色卡片边框
    var darkCardBorder: Color {
        Color.white.opacity(0.2)
    }
}

//
//  Float+.swift
//  YUI
//
//  Created by 赵翔宇 on 2025/3/12.
//

import Foundation

extension Float {
    func string() -> String {
        // 判断是否为整数
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else {
            // 最多保留两位小数，去掉末尾的0
            return String(format: "%.2f", self).replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression).replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
        }
    }
}

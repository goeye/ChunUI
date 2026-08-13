//
//  String+.swift
//  YUI
//
//  Created by 赵翔宇 on 2025/3/1.
//

 

extension String{
    
    /// 生成随机中文字符串
    /// - Parameter length: 期望的字符串长度
    /// - Returns: 随机中文字符串，长度在传入长度的前后随机波动
    static func randomChineseString(length: Int) -> String {
        // 中文Unicode范围：0x4e00 - 0x9fff
        let chineseStart = 0x4e00
        let chineseEnd = 0x9fff
        
        // 计算最终长度，在传入长度的前后随机波动
        let variance = Int.random(in: -Swift.min(3, length/2)...Swift.min(3, length/2))
        let finalLength = Swift.max(1, length + variance) // 确保长度至少为1
        
        var result = ""
        
        for _ in 0..<finalLength {
            // 随机选择一个中文字符的Unicode值
            let randomScalar = UnicodeScalar(Int.random(in: chineseStart...chineseEnd))!
            result.append(Character(randomScalar))
        }
        
        return result
    }
    
    
    func or(_ or : String) -> String{
        if self.isEmpty{
            return or
        }else{
            return self
        }
    }

    /// 限制字符串长度，超出部分用 "..." 替代
    /// - Parameter maxLength: 最大字符数
    /// - Returns: 截断后的字符串
    func limitedTo(_ maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength)) + "..."
    }
}

extension Optional where Wrapped == String {
    /// 如果字符串为nil或空，则返回or参数的值
    /// - Parameter or: 当字符串为nil或空时返回的值
    /// - Returns: 原字符串或or参数的值
    func or(_ or: String) -> String {
        if let self = self, !self.isEmpty {
            return self
        } else {
            return or
        }
    }
}

extension String {
    /// 将UTC时间字符串转换为本地时区的时间字符串
    /// - Parameter format: 输出的日期格式，默认为"yyyy-MM-dd HH:mm"
    /// - Returns: 本地时区的时间字符串
    func toLocalTimeString(format: String = "yyyy-MM-dd HH:mm") -> String? {
        let formatter = DateFormatter()
        
        // 尝试解析包含毫秒的格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: self) {
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = format
            return formatter.string(from: date)
        }
        
        // 尝试解析不包含毫秒的格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let date = formatter.date(from: self) else { return nil }
        
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    /// 将UTC时间字符串转换为本地时区的Date对象
    /// - Returns: 本地时区的Date对象
    func toLocalTimeDate() -> Date {
        let formatter = DateFormatter()
        // 尝试解析包含毫秒的格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = formatter.date(from: self) {
            return date
        }
        // 尝试解析不包含毫秒的格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        guard let date = formatter.date(from: self) else { return .now }
        return date
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 手机号掩码
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension String {
    /// 手机号掩码（去除国家码 + 中间掩码）
    /// - 输入: "+8613812345678" / "8613812345678" / "13812345678"
    /// - 输出: "138****5678"
    func maskedPhone() -> String {
        var cleaned = self

        // 移除国家区号前缀
        if cleaned.hasPrefix("+86") {
            cleaned = String(cleaned.dropFirst(3))
        } else if cleaned.hasPrefix("86") && cleaned.count > 11 {
            cleaned = String(cleaned.dropFirst(2))
        }

        // 确保是 11 位手机号
        guard cleaned.count == 11 else {
            return "***"
        }

        // 格式：前3位 + **** + 后4位
        let prefix = cleaned.prefix(3)
        let suffix = cleaned.suffix(4)
        return "\(prefix)****\(suffix)"
    }
}

extension Date {
    /// 将 Date 格式化为指定格式的字符串，支持指定时区（默认为 UTC）
    ///
    /// - Parameters:
    ///   - pattern: 日期格式，默认使用 ISO 风格的 `"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"`
    ///   - timeZone: 时区，默认是 UTC（格林威治时间）
    /// - Returns: 格式化后的字符串
    func toTimeZoneString(
        _ pattern: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
        timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = pattern
        formatter.timeZone = timeZone
        return formatter.string(from: self)
    }
}

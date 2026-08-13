//import UIKit
//import ImageIO
//import Photos
//
//extension UIImage {
//    /// 从图片EXIF数据中获取拍摄时间
//    /// - Returns: 拍摄时间的字符串，如果没有则返回nil
//    func getCaptureDateFromEXIF() -> Date? {
//        // 尝试从UIImage获取关联的图像数据
//        guard let imageData = self.jpegData(compressionQuality: 1.0) else {
//            return nil
//        }
//        
//        let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil)
//        guard let imgSrc = imageSource,
//              let properties = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, nil) as? [String: Any] else {
//            return nil
//        }
//        
//        // 尝试获取EXIF中的拍摄时间
//        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
//           let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
//            // EXIF日期格式: "YYYY:MM:DD HH:MM:SS"
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
//            return dateFormatter.date(from: dateTimeOriginal)
//        }
//        
//        // 也可以尝试从TIFF字典获取
//        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
//           let dateTime = tiff[kCGImagePropertyTIFFDateTime as String] as? String {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
//            return dateFormatter.date(from: dateTime)
//        }
//        
//        // 尝试从GPS字典获取
//        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
//           let dateStamp = gps[kCGImagePropertyGPSDateStamp as String] as? String,
//           let timeStamp = gps[kCGImagePropertyGPSTimeStamp as String] as? String {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
//            return dateFormatter.date(from: "\(dateStamp) \(timeStamp)")
//        }
//        
//        // 如果都没找到，返回nil
//        return nil
//    }
//    
//    /// 获取格式化的拍摄时间字符串
//    /// - Returns: 格式化的日期字符串，如果未找到则返回当前时间
//    func getFormattedCaptureDate() -> String {
//        let date = getCaptureDateFromEXIF() ?? Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        return dateFormatter.string(from: date)
//    }
//}
//
//// 使用PHAsset的创建日期作为备选
//extension UIImage {
//    /// 尝试从相册资源获取创建日期
//    /// - Parameter asset: PHAsset对象
//    /// - Returns: 日期字符串
//    static func getDateFromPHAsset(asset: PHAsset) -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        return dateFormatter.string(from: asset.creationDate ?? Date())
//    }
//}

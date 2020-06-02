//
//  StickerUtils.swift
//  SSticker
//
//  Created by 王杰 on 2020/5/30.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
    // short Path
    func generateShortPath(width: Int = DefaultStickerWidth, height: Int = DefaultStickerWidth) -> String {
        return StickerStickerGeneratePath + "/" + self.md5 + "_\(width)" + "_\(height)"
    }
    
    // preview Path
    func generatePreviewPath(width: Int = DefaultStickerWidth, height: Int = DefaultStickerWidth) -> String {
        return StickerStickerPreViewPath + "/" + self.md5 + "_\(width)" + "_\(height)"
    }
    
}


extension Data {
    
    func wr_MD5Hash() -> String {
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let _ = withUnsafeBytes { bytes in
            CC_MD5(bytes, CC_LONG(self.count), result)
        }
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.deallocate()
        
        return String(format: hash as String)
    }
}

extension NSData {
    @objc func wr_MD5Hash() -> String {
        return (self as Data).wr_MD5Hash().lowercased()
    }
}

// MARK: - String+md5
extension String {
    
    var md5: String {
        let md5Length = Int(CC_MD5_DIGEST_LENGTH)
        var result: [CUnsignedChar] = Array(repeating: 0, count: md5Length)
        let data = cString(using: .utf8)!
        CC_MD5(data, CC_LONG(data.count-1), &result)
        return (0..<md5Length).reduce("") { $0 + String(format: "%02hhx", result[$1])}
    }
    
    var md5TGS: String {
        let md5Length = Int(CC_MD5_DIGEST_LENGTH)
        var result: [CUnsignedChar] = Array(repeating: 0, count: md5Length)
        let data = cString(using: .utf8)!
        CC_MD5(data, CC_LONG(data.count-1), &result)
        let str = (0..<md5Length).reduce("") { $0 + String(format: "%02hhx", result[$1])}
        return str + ".tgs"
    }
}


// MARK: - String+utf8Data
extension String {
    var utf8Data: Data {
        return data(using: .utf8)!
    }
}


extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xff) / 255.0, green: CGFloat((rgb >> 8) & 0xff) / 255.0, blue: CGFloat(rgb & 0xff) / 255.0, alpha: 1.0)
    }
}

extension Optional where Wrapped == CGSize  {
    
    var stickerWidth: CGFloat {
        if let s = self {
            return s.width
        }
        return CGFloat(DefaultStickerWidth)
    }
    
    
    var stickerHeight: CGFloat {
        if let s = self {
            return s.height
        }
        return CGFloat(DefaultStickerWidth)
    }
}

//
//  ToCombinedMp4.swift
//  SStickDemo
//
//  Created by 王杰 on 2020/5/29.
//  Copyright © 2020 王杰. All rights reserved.
//

import UIKit
import Foundation
import RLottieBinding
import Compression

@available(iOS 9.0, *)
func experimentalConvertCompressedLottieToCombinedMp4(data: Data, size: CGSize, depath: String, completion: ((String) -> Void)?) {
    
    let startTime = CACurrentMediaTime()
    var drawingTime: Double = 0
    var appendingTime: Double = 0
    var deltaTime: Double = 0
    var compressionTime: Double = 0
    
    let decompressedData = data
    if let player = LottieInstance(data: decompressedData, cacheKey: depath) {
        let endFrame = Int(player.frameCount)
        
        var randomId: Int64 = 0
        arc4random_buf(&randomId, 8)
        let path = depath
        guard let fileContext = ManagedFile(queue: nil, path: path, mode: .readwrite) else {
            return
        }
        
        let bytesPerRow = (4 * Int(size.width) + 15) & (~15)
        
        var currentFrame: Int32 = 0
        
        var fps: Int32 = player.frameRate
        var frameCount: Int32 = player.frameCount
        let _ = fileContext.write(&fps, count: 4)
        let _ = fileContext.write(&frameCount, count: 4)
        var widthValue: Int32 = Int32(size.width)
        var heightValue: Int32 = Int32(size.height)
        var bytesPerRowValue: Int32 = Int32(bytesPerRow)
        let _ = fileContext.write(&widthValue, count: 4)
        let _ = fileContext.write(&heightValue, count: 4)
        let _ = fileContext.write(&bytesPerRowValue, count: 4)
        
        let frameLength = bytesPerRow * Int(size.height)
        assert(frameLength % 16 == 0)
        
        let currentFrameData = malloc(frameLength)!
        memset(currentFrameData, 0, frameLength)
        
        let yuvaPixelsPerAlphaRow = (Int(size.width) + 1) & (~1)
        assert(yuvaPixelsPerAlphaRow % 2 == 0)
        
        let yuvaLength = Int(size.width) * Int(size.height) * 2 + yuvaPixelsPerAlphaRow * Int(size.height) / 2
        var yuvaFrameData = malloc(yuvaLength)!
        memset(yuvaFrameData, 0, yuvaLength)
        
        var previousYuvaFrameData = malloc(yuvaLength)!
        memset(previousYuvaFrameData, 0, yuvaLength)
        
        defer {
            free(currentFrameData)
            free(previousYuvaFrameData)
            free(yuvaFrameData)
        }
        
        var compressedFrameData = Data(count: frameLength)
        let compressedFrameDataLength = compressedFrameData.count
        
        let scratchData = malloc(compression_encode_scratch_buffer_size(COMPRESSION_LZFSE))!
        defer {
            free(scratchData)
        }
        
        while currentFrame < endFrame {
            
            let drawStartTime = CACurrentMediaTime()
            memset(currentFrameData, 0, frameLength)
            player.renderFrame(with: Int32(currentFrame), into: currentFrameData.assumingMemoryBound(to: UInt8.self), width: Int32(size.width), height: Int32(size.height), bytesPerRow: Int32(bytesPerRow))
            drawingTime += CACurrentMediaTime() - drawStartTime
            
            let appendStartTime = CACurrentMediaTime()
            
            encodeRGBAToYUVA(yuvaFrameData.assumingMemoryBound(to: UInt8.self), currentFrameData.assumingMemoryBound(to: UInt8.self), Int32(size.width), Int32(size.height), Int32(bytesPerRow))
            
            appendingTime += CACurrentMediaTime() - appendStartTime
            
            let deltaStartTime = CACurrentMediaTime()
            var lhs = previousYuvaFrameData.assumingMemoryBound(to: UInt64.self)
            var rhs = yuvaFrameData.assumingMemoryBound(to: UInt64.self)
            for _ in 0 ..< yuvaLength / 8 {
                lhs.pointee = rhs.pointee ^ lhs.pointee
                lhs = lhs.advanced(by: 1)
                rhs = rhs.advanced(by: 1)
            }
            var lhsRest = previousYuvaFrameData.assumingMemoryBound(to: UInt8.self).advanced(by: (yuvaLength / 8) * 8)
            var rhsRest = yuvaFrameData.assumingMemoryBound(to: UInt8.self).advanced(by: (yuvaLength / 8) * 8)
            for _ in (yuvaLength / 8) * 8 ..< yuvaLength {
                lhsRest.pointee = rhsRest.pointee ^ lhsRest.pointee
                lhsRest = lhsRest.advanced(by: 1)
                rhsRest = rhsRest.advanced(by: 1)
            }
            deltaTime += CACurrentMediaTime() - deltaStartTime
            
            let compressionStartTime = CACurrentMediaTime()
            compressedFrameData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
                let length = compression_encode_buffer(bytes, compressedFrameDataLength, previousYuvaFrameData.assumingMemoryBound(to: UInt8.self), yuvaLength, scratchData, COMPRESSION_LZFSE)
                var frameLengthValue: Int32 = Int32(length)
                let _ = fileContext.write(&frameLengthValue, count: 4)
                let _ = fileContext.write(bytes, count: length)
            }
            
            let tmp = previousYuvaFrameData
            previousYuvaFrameData = yuvaFrameData
            yuvaFrameData = tmp
            
            compressionTime += CACurrentMediaTime() - compressionStartTime
            
            currentFrame += 1
        }
        
        completion?(path)
        
        print("animation render time \(CACurrentMediaTime() - startTime)")
        print("of which drawing time \(drawingTime)")
        print("of which appending time \(appendingTime)")
        print("of which delta time \(deltaTime)")
        
        print("of which compression time \(compressionTime)")
    }
    
    return
}




let colorKeyRegex = try? NSRegularExpression(pattern: "\"k\":\\[[\\d\\.]+\\,[\\d\\.]+\\,[\\d\\.]+\\,[\\d\\.]+\\]")


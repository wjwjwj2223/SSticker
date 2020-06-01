//
//  AnimatedStickerFrameQueue.swift
//  SStickDemo
//
//  Created by 王杰 on 2020/5/28.
//  Copyright © 2020 王杰. All rights reserved.
//

import UIKit
import SDWebImage

let decodeImageQueue = DispatchQueue(label: "decodeImageQueue")

public class StickerAnimatedImageView: UIImageView {
    
    let queue = decodeImageQueue
    private let timer = Atomic<STimer?>(value: nil)
    private var url: String?
//    private var generateImageOperation: GenerateImageOperation?
    private var cachedData: Data?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        print("StickerAnimatedImageView -------- init")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.timer.swap(nil)?.invalidate()
//        generateImageOperation?.cancel()
//        generateImageOperation?.isFinished = true
        print("StickerAnimatedImageView -------- deinit")
    }
    
    public func clear() {
        self.timer.swap(nil)?.invalidate()
        self.url = nil
        self.cachedData = nil
        self.image = nil
    }
    
    public func setSecretAnimation(_ with: URL,
                                   _ size: CGSize? = nil,
                                   _ placeHolder: UIImage? = nil) {
        
        self.url = with.absoluteString
        
        let timerHolder = self.timer
        
        timerHolder.swap(nil)?.invalidate()
        
        
        if let place = placeHolder {
            self.image = place
        } else {
            self.image = nil
        }
        
        guard with.absoluteString.hasPrefix("http") else {
            return
        }
        
        if with.absoluteString.hasSuffix("tgs") {
            
            let shortPath = with.absoluteString.generateShortPath(width: Int(size.stickerWidth), height: Int(size.stickerWidth))
//
//            if FileManager.default.fileExists(atPath: shortPath) {
//                self.playWithPath(shortPath, isFirstFrame: true)
//            }
            
            self.queue.async { [weak self] in
                
                guard let self = self else {return}
                
                if FileManager.default.fileExists(atPath: shortPath) {
                    self.playWithPath(shortPath)
                } else {
                    downloadResourceWith(with) { (origin , path) in
                        guard self.url == origin else {return}
                        let optionData = try? Data(contentsOf: URL(fileURLWithPath: path), options: [.mappedRead])
                        guard let pData = optionData else {return}
                        experimentalConvertCompressedLottieToCombinedMp4(data: pData, size: CGSize(width: size.stickerWidth, height: size.stickerHeight), depath: shortPath, completion: { path in
                            self.playWithPath(path)
                        })
                    }
                }
            }
        }
    }
    
    private func playWithPath(_ path: String, isFirstFrame: Bool = false) {
        
        if let fileData = try? Data(contentsOf: URL(fileURLWithPath: path), options: [.mappedRead]){
            self.cachedData = fileData
        }
        var maybeFrameSource: AnimatedStickerCachedFrameSource?
        if let cacheDa = self.cachedData {
            maybeFrameSource = AnimatedStickerCachedFrameSource(queue: self.queue, data: cacheDa)
        }
        
        guard let frameSource = maybeFrameSource else {
            return
        }
//        if let operation = generateImageOperation {
//            print("operation--------重新赋值")
//            operation.frameSource = frameSource
//            operation.frameQueue = AnimatedStickerFrameQueue(queue: self.queue, length: 1, source: frameSource)
//        } else {
//            print("operation--------创建")
//            generateImageOperation = GenerateImageOperation(queue:self.queue, imageView: self, frameSource: frameSource)
//            generateImageQueue.addOperation(generateImageOperation!)
//        }
        let frameQueue = QueueLocalObject<AnimatedStickerFrameQueue>(queue: self.queue, generate: {
            return AnimatedStickerFrameQueue(queue: self.queue, length: 1, source: frameSource)
        })
        
        let timerHolder = self.timer
        
        let timer = STimer(timeout: 1.0 / Double(60), repeat: !isFirstFrame, completion: {
            [weak self] in
            guard let self = self else {return}
            let frame = frameSource.takeFrame()
            self.queue.async {
                [weak self] in
                guard let self = self else {return}
                self.render(width: frame.width, height: frame.height, bytesPerRow: frame.bytesPerRow, data: frame.data)
            }
            frameQueue.with { frameQueue in
                frameQueue.generateFramesIfNeeded()
            }
        }, queue: queue)
        let _ = timerHolder.swap(timer)
        timer.start()
    }
    
    func render(width: Int, height: Int, bytesPerRow: Int, data: Data) {
        let calculatedBytesPerRow = (4 * Int(width) + 15) & (~15)
        assert(bytesPerRow == calculatedBytesPerRow)
        let image = generateImagePixel(CGSize(width: CGFloat(width), height: CGFloat(height)), scale: 1.0, pixelGenerator: { _, pixelData, bytesPerRow in
            data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                decodeYUVAToRGBA(bytes, pixelData, Int32(width), Int32(height), Int32(bytesPerRow))
            }
        })
        DispatchQueue.main.async { [weak self] in
            self?.image = image
        }
    }
}

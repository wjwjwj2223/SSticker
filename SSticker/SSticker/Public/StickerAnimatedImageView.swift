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
let firstFrameImageQueue = DispatchQueue(label: "firstFrameImageQueue", qos: DispatchQoS.userInitiated, attributes: .concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem, target: nil)
//let firstFrameImageQueue = DispatchQueue(label: "firstFrameImageQueue")
//let generateCacheFileQueue = DispatchQueue(label: "generateCacheFileQueue", qos: DispatchQoS.background, attributes: .concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem, target: nil)
let generateCacheFileQueue = DispatchQueue(label: "generateCacheFileQueue")


public class StickerAnimatedImageView: UIImageView {
    
    let queue = decodeImageQueue
    let ffQueue = firstFrameImageQueue
    let fileQueue = generateCacheFileQueue
    private let timer = Atomic<STimer?>(value: nil)
    private var url: String?
    private var currentLoadPath: String?
    private var currentPreViewPath: String?
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
        
        guard self.url != with.absoluteString else {
            return
        }
        
        self.url = with.absoluteString
        
        let timerHolder = self.timer
        
        timerHolder.swap(nil)?.invalidate()
        
        
        if let place = placeHolder {
            self.image = place
        } else {
            self.image = UIImage(named: "biaoqing")
        }
        
        guard with.absoluteString.hasPrefix("http") else {
            return
        }
        
        if with.absoluteString.hasSuffix("tgs") {
            
            self.currentLoadPath = with.absoluteString.generateShortPath(width: Int(size.stickerWidth), height: Int(size.stickerWidth))
            
            self.currentPreViewPath = with.absoluteString.generatePreviewPath(width: Int(size.stickerWidth), height: Int(size.stickerWidth))
            
            guard let shortPath = currentLoadPath, let preViewPath = currentPreViewPath else {return}
            
            let existPreViewData = FileManager.default.fileExists(atPath: preViewPath)
            let existShortData = FileManager.default.fileExists(atPath: shortPath)
            
            let ul = URL(fileURLWithPath: preViewPath)
            if existPreViewData, let preData = try? Data(contentsOf: ul) {
                self.image = UIImage(data: preData)
            }
            
            if !existPreViewData && existShortData {
                //缓存第一帧
                self.playWithPath(shortPath, isFirstFrame: true)
            }
            
            if existShortData {
                self.queue.async {
                    self.playWithPath(shortPath)
                }
                return
            }
            
            downloadResourceWith(with) { [weak self] (origin , path) in
                guard let self = self else {return}
                guard self.url == origin else {return}
                self.fileQueue.async { [weak self] in
                    let optionData = try? Data(contentsOf: URL(fileURLWithPath: path), options: [.mappedRead])
                    guard let pData = optionData else {return}
                    guard let self = self else {return}
                    experimentalConvertCompressedLottieToCombinedMp4(data: pData, size: CGSize(width: size.stickerWidth, height: size.stickerHeight), depath: shortPath, completion: { path in
                        self.queue.async {
                            self.playWithPath(path)
                        }
                    })
                }
            }
        }
    }
    
    private func playWithPath(_ path: String, isFirstFrame: Bool = false) {
        
        guard path == self.currentLoadPath else {return}
        
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
        let frameQueue = QueueLocalObject<AnimatedStickerFrameQueue>(queue: self.queue, generate: {
            return AnimatedStickerFrameQueue(queue: self.queue, length: 1, source: frameSource)
        })
        
        let timerHolder = self.timer
        let timer = STimer(timeout: 1.0 / Double(60), repeat: !isFirstFrame, completion: {
            [weak self] in
            guard let self = self else {return}
            let frame = frameSource.takeFrame()
            self.render(url: path, width: frame.width, height: frame.height, bytesPerRow: frame.bytesPerRow, data: frame.data, isFirst: isFirstFrame)
            frameQueue.with { frameQueue in
                frameQueue.generateFramesIfNeeded()
            }
        }, queue: isFirstFrame ? ffQueue : queue)
        let _ = timerHolder.swap(timer)
        timer.start()
    }
    
    func render(url: String, width: Int, height: Int, bytesPerRow: Int, data: Data, isFirst: Bool = false) {
        let calculatedBytesPerRow = (4 * Int(width) + 15) & (~15)
        assert(bytesPerRow == calculatedBytesPerRow)
        let image = generateImagePixel(CGSize(width: CGFloat(width), height: CGFloat(height)), scale: 1.0, pixelGenerator: { _, pixelData, bytesPerRow in
            data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                decodeYUVAToRGBA(bytes, pixelData, Int32(width), Int32(height), Int32(bytesPerRow))
            }
        })
        guard url == self.currentLoadPath, let ur = self.url else {return}
        
        if isFirst, let img = image, let data = img.pngData() {
            let u = ur.generatePreviewPath(width: width, height: height)
            let ul = URL(fileURLWithPath: u)
            try? data.write(to: ul)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            guard url == self.currentLoadPath else {return}
            self.image = image
        }
    }
}

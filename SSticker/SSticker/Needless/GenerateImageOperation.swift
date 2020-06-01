//
//  GenerateImageOperation.swift
//  SSticker
//
//  Created by 王杰 on 2020/5/30.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation

var generateImageQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 60
    return queue
}()

class GenerateImageOperation: Operation {
    
    weak var imageView: UIImageView?
    var timer: Timer?
    var queue: DispatchQueue
    var frameSource: AnimatedStickerCachedFrameSource
    var frameQueue: AnimatedStickerFrameQueue?
    
    init(queue: DispatchQueue, imageView: UIImageView, frameSource: AnimatedStickerCachedFrameSource) {
        self.imageView = imageView
        self.frameSource = frameSource
        self.queue = queue
        self.frameQueue = AnimatedStickerFrameQueue(queue: queue, length: 1, source: frameSource)
    }
    
    deinit {
        print("GenerateImageOperation ------- deinit")
    }
    
    override func start() {
        generateImageQueue.operations.forEach { (o) in
            if let go = o as? GenerateImageOperation, o.isFinished {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: {
                    go.isFinished = true
                })
            }
        }
        super.start()
    }
    
    override func main() {
//        print("++++++++开启定时器+++++++++")
         timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(60), repeats: true) {  [weak self] (timer) in
            guard let self = self else {return}
            decodeImageQueue.async {
                let maybeFrame = self.frameSource.takeFrame()
                self.render(width: maybeFrame.width, height: maybeFrame.height, bytesPerRow: maybeFrame.bytesPerRow, data: maybeFrame.data)
                self.frameQueue?.generateFramesIfNeeded()
            }
        }
        timer?.fire()
        RunLoop.current.add(timer!, forMode: .common)
        RunLoop.current.run()
    }
    
    override func cancel() {
        timer?.invalidate()
        print("++++++++销毁定时器+++++++++")
    }
    
    var _isFinished: Bool = false
    
    override var isFinished: Bool {
        
        set {
            self.willChangeValue(forKey: "isFinished")
            self._isFinished = true
            self.didChangeValue(forKey: "isFinished")
        }
        
        get {
            return self._isFinished
        }
    }
    
    private func render(width: Int, height: Int, bytesPerRow: Int, data: Data) {
        let calculatedBytesPerRow = (4 * Int(width) + 15) & (~15)
        assert(bytesPerRow == calculatedBytesPerRow)
        let image = generateImagePixel(CGSize(width: CGFloat(width), height: CGFloat(height)), scale: 1.0, pixelGenerator: { _, pixelData, bytesPerRow in
            data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                decodeYUVAToRGBA(bytes, pixelData, Int32(width), Int32(height), Int32(bytesPerRow))
            }
        })
        DispatchQueue.main.async { [weak self] in
            self?.imageView?.image = image
        }
    }
    
}

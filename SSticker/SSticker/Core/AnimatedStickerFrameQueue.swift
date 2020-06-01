//
//  AnimatedStickerFrameQueue.swift
//  SStickDemo
//
//  Created by 王杰 on 2020/5/28.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation

class AnimatedStickerFrameQueue {
    private let queue: DispatchQueue
    private let length: Int
    private let source: AnimatedStickerCachedFrameSource
    private var frames: [AnimatedStickerFrame] = []
    
    init(queue: DispatchQueue, length: Int, source: AnimatedStickerCachedFrameSource) {
        self.queue = queue
        self.length = length
        self.source = source
    }

    
    func take() -> AnimatedStickerFrame? {
        if self.frames.isEmpty {
            self.frames.append(self.source.takeFrame())
        }
        if !self.frames.isEmpty {
            let frame = self.frames.removeFirst()
            return frame
        } else {
            return nil
        }
    }
    
    func generateFramesIfNeeded() {
        if self.frames.isEmpty {
            self.frames.append(self.source.takeFrame())
        }
    }
}

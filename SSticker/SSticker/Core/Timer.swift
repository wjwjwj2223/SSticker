//
//  Timer.swift
//  SSticker
//
//  Created by 王杰 on 2020/5/31.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation

final class STimer {
    private let timer = Atomic<DispatchSourceTimer?>(value: nil)
    private let timeout: Double
    private let `repeat`: Bool
    private let completion: () -> Void
    private let queue: DispatchQueue
    
    init(timeout: Double, `repeat`: Bool, completion: @escaping() -> Void, queue: DispatchQueue) {
        self.timeout = timeout
        self.`repeat` = `repeat`
        self.completion = completion
        self.queue = queue
    }
    
    deinit {
        self.invalidate()
    }
    
    func start() {
        let timer = DispatchSource.makeTimerSource(queue: self.queue)
        timer.setEventHandler(handler: { [weak self] in
            if let strongSelf = self {
                strongSelf.completion()
                if !strongSelf.`repeat` {
                    strongSelf.invalidate()
                }
            }
        })
        let _ = self.timer.modify { _ in
            return timer
        }
        
        if self.`repeat` {
            let time: DispatchTime = DispatchTime.now() + self.timeout
            timer.schedule(deadline: time, repeating: self.timeout)
        } else {
            let time: DispatchTime = DispatchTime.now() + self.timeout
            timer.schedule(deadline: time)
        }
        
        timer.resume()
    }
    
    func invalidate() {
        let _ = self.timer.modify { timer in
            timer?.cancel()
            return nil
        }
    }
}

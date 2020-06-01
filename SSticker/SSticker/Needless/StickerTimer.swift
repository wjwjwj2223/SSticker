//
//  StickerTimer.swift
//  SSticker
//
//  Created by 王杰 on 2020/5/30.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation

class StickerTimer {
    
    static let shared: StickerTimer = StickerTimer()
    
    let queue: DispatchQueue
    var timer: DispatchSourceTimer
    var isSuspend: Bool = true
    var events: [String: () -> Void] = [:]
    
    init() {
        self.queue = DispatchQueue(label: "StickerTimerQueue")
        self.timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        self.timer.schedule(deadline: .now(), repeating: 1.0 / Double(60))
        self.timer.setEventHandler(handler: { [weak self] in
            self?.play()
        })
    }
    
    func play() {
        if self.events.count == 0 {
            self.timer.suspend()
            self.isSuspend = true
        }
        self.events.values.forEach{$0()}
    }
    
    
    func addEvent(key: String, event: @escaping ()-> Void) {
        queue.async {
            if self.isSuspend {
                self.timer.resume()
                self.isSuspend = false
            }
            self.events[key] = event
        }
    }
    
    func removeEvent(key: String) {
        queue.async {
            self.events.removeValue(forKey: key)
        }
    }
  
}

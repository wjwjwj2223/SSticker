//
//  QueueLocalObject.swift
//  SSticker
//
//  Created by 王杰 on 2020/5/31.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation

public final class QueueLocalObject<T: AnyObject> {
    public let queue: DispatchQueue
    private var valueRef: Unmanaged<T>?
    
    public init(queue: DispatchQueue, generate: @escaping () -> T) {
        self.queue = queue
        
        self.queue.async {
            let value = generate()
            self.valueRef = Unmanaged.passRetained(value)
        }
    }
    
    deinit {
        let valueRef = self.valueRef
        self.queue.async {
            valueRef?.release()
        }
    }
    
    public func with(_ f: @escaping (T) -> Void) {
        self.queue.async {
            if let valueRef = self.valueRef {
                let value = valueRef.takeUnretainedValue()
                f(value)
            }
        }
    }
    
    public func syncWith<R>(_ f: @escaping (T) -> R) -> R? {
        var result: R?
        self.queue.sync {
            if let valueRef = self.valueRef {
                let value = valueRef.takeUnretainedValue()
                result = f(value)
            }
        }
        return result
    }
}


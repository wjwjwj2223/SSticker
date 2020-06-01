//
//  Atomic.swift
//  SSticker
//
//  Created by 王杰 on 2020/5/31.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation

final class Atomic<T> {
    private var lock: pthread_mutex_t
    private var value: T
    
    init(value: T) {
        self.lock = pthread_mutex_t()
        self.value = value
        
        pthread_mutex_init(&self.lock, nil)
    }
    
    deinit {
        pthread_mutex_destroy(&self.lock)
    }
    
    func with<R>(_ f: (T) -> R) -> R {
        pthread_mutex_lock(&self.lock)
        let result = f(self.value)
        pthread_mutex_unlock(&self.lock)
        
        return result
    }
    
    func modify(_ f: (T) -> T) -> T {
        pthread_mutex_lock(&self.lock)
        let result = f(self.value)
        self.value = result
        pthread_mutex_unlock(&self.lock)
        
        return result
    }
    
    func swap(_ value: T) -> T {
        pthread_mutex_lock(&self.lock)
        let previous = self.value
        self.value = value
        pthread_mutex_unlock(&self.lock)
        
        return previous
    }
}


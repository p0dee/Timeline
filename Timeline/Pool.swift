//
//  Pool.swift
//  Timeline
//
//  Created by Takeshi Tanaka on 2/13/16.
//  Copyright © 2016 p0dee. All rights reserved.
//

import Foundation

class Pool<T> {
    
    typealias ItemFactoryCallback = () -> T
    private var items = [T]()
    private var itemCount: Int = 0
    private let maxItemCount: Int
    private let factoryCallback: ItemFactoryCallback
    private let queue = dispatch_queue_create("com.p0dee.PoolQueue", DISPATCH_QUEUE_SERIAL)
    private let semaphore: dispatch_semaphore_t
    
    init(maxItemCount: Int, factoryCallback: ItemFactoryCallback) {
        self.maxItemCount = maxItemCount
        self.factoryCallback = factoryCallback
        semaphore = dispatch_semaphore_create(self.maxItemCount)
    }
    
    func enqueue(object: T) {
        dispatch_async(queue) { () -> Void in
            self.items.append(object)
            dispatch_semaphore_signal(self.semaphore)
        }
    }
    
    func dequeue() -> T? {
        var ret: T?
        if dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER) == 0 {
            dispatch_sync(queue) { () -> Void in
                if self.items.count == 0 && self.itemCount < self.maxItemCount {
                    ret = self.factoryCallback()
                    self.itemCount++
                } else {
                    ret = self.items.removeLast()
                }
                print("items.count: ", self.items.count, " itemCount:", self.itemCount)
            }
        }
        return ret
    }

}

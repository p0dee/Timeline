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
    private let queue = DispatchQueue(label: "com.p0dee.PoolQueue")
    private let semaphore: DispatchSemaphore
    
    init(maxItemCount: Int, factoryCallback: @escaping ItemFactoryCallback) {
        self.maxItemCount = maxItemCount
        self.factoryCallback = factoryCallback
        semaphore = DispatchSemaphore(value: self.maxItemCount)
    }
    
    func enqueue(object: T) {
        queue.async() { () -> Void in
            self.items.append(object)
            self.semaphore.signal()
        }
    }
    
    func dequeue() -> T? {
        var ret: T?
        if semaphore.wait(timeout: DispatchTime.distantFuture) == .success {
            queue.sync() { () -> Void in
                if self.items.count == 0 && self.itemCount < self.maxItemCount {
                    ret = self.factoryCallback()
                    self.itemCount += 1
                } else {
                    ret = self.items.removeLast()
                }
                print("items.count: ", self.items.count, " itemCount:", self.itemCount)
            }
        }
        return ret
    }

}

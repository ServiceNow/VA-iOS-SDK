//
//  ListenerList.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/22/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

class ListenerList<T> where T: AnyObject {
    
    private var listeners = [WeakRef<T>]()
    
    var count: Int {
        compact()
        return listeners.count
    }
    
    public func addListener(_ listener: T) {
        compact()

        let wrapper = WeakRef(value: listener)
        listeners.append(wrapper)
    }
    
    public func removeListener(_ listener: T) {
        compact()
        
        guard let index = listeners.index(where: { $0.value === listener }) else { return }
        
        listeners.remove(at: index)
    }
    
    public func forEach<RT>(withType _: RT.Type, _ closure: (_: RT) -> Void ) {
        compact()
        
        listeners.forEach { wrapper in
            if let listener = wrapper.value {
                closure(listener as! RT)
            }
        }
    }
    
    private func compact() {
        let newList = listeners.filter { $0.value != nil }
        
        let delta = listeners.count - newList.count
        Logger.default.logInfo("ListenerList compacted \(delta) nil-items")
        
        listeners = newList
    }
    
    init() {
        
    }
}

class WeakRef<T> where T: AnyObject {
    
    private(set) weak var value: T?
    
    init(value: T?) {
        self.value = value
    }
}

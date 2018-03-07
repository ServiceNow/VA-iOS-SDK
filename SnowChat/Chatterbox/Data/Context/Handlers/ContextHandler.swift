//
//  ContextHandler.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

protocol ContextHandler {
    
    var isAuthorized: Bool { get }
    
    var contextItem: ContextItem? { get set }
    
    func authorize(completion: @escaping (Bool) -> Swift.Void)
}

// TODO: Depending if we add location this will be uncommented and used
protocol DataFetchable {
    
    // On init we have to request data. When frequence is supported we should use commented method below
//    func fetchData(completion: @escaping (AnyObject?) -> Swift.Void)
    
    // TODO: when we will support frequency, we can use this method. Block should be dispatched with frequency value.
    //    func scheduledDataFetch(block: @escaping (Bool) -> Swift.Void)
}

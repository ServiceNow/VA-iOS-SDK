//
//  ContextHandler.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

protocol ContextHandler {
    
    var contextItem: ContextItem { get }
    
    // TODO: We are not using it for now since frequency is not supported.
    // Each ContextHandler has corresponding ContextTtem
    init(contextItem: ContextItem)
    
    func authorize(completion: @escaping (Bool) -> Swift.Void)
}

protocol DataFetchable {
    
    // On init we have to request data. When frequence is supported we should use commented method below
//    func fetchData(completion: @escaping (AnyObject?) -> Swift.Void)
    
    // TODO: when we will support frequency, we can use this method. Block should be dispatched with frequency value.
    //    func scheduledDataFetch(block: @escaping (Bool) -> Swift.Void)
}

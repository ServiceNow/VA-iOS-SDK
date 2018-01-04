//
//  APIManager+ChatTopics.swift
//  SnowChat
//
//  Created by Will Lisac on 12/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

extension APIManager {
    
    func suggestTopics(searchText: String, completionHandler: @escaping([CBTopic]) -> Void) {
        sessionManager.request(apiURLWithPath("cs/topics/suggest"),
            method: .get,
            parameters: ["sysparm_message" : searchText],
            encoding: URLEncoding.queryString).validate().responseJSON { response in
                var topics = [CBTopic]()
                
                if response.error == nil {
                    if let result = response.result.value {
                        topics = APIManager.topicsFromResult(result)
                    }
                }
                completionHandler(topics)
        }
    }
    
    func allTopics(completionHandler: @escaping ([CBTopic]) -> Void) {
        sessionManager.request(apiURLWithPath("cs/topics/tree"),
            method: .get,
            encoding: JSONEncoding.default).validate().responseJSON { response in
                var topics = [CBTopic]()
                if response.error == nil {
                    if let result = response.result.value {
                        topics = APIManager.topicsFromResult(result)
                    }
                }
                completionHandler(topics)
        }
    }
    
    // MARK: - Response Parsing
    
    static func topicsFromResult(_ result: Any) -> [CBTopic] {
        guard let dictionary = result as? NSDictionary,
            let topicDictionaries = dictionary["root"] as? [NSDictionary] else { return [] }
        
        let topics: [CBTopic] = topicDictionaries.flatMap { topic in
            guard let title = topic["title"] as? String, let name = topic["topicName"] as? String else { return nil }
            return CBTopic(title: title, name: name)
        }
        
        return topics
    }
    
}

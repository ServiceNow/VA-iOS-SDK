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
    
    func suggestTopics(searchText: String, completionHandler: @escaping([ChatTopic]) -> Void) {
        sessionManager.request(apiURLWithPath("cs/topics/suggest"),
            method: .get,
            parameters: ["sysparm_message" : searchText],
            encoding: URLEncoding.queryString).validate().responseJSON { response in
                
                var topics = [ChatTopic]()
                if response.error == nil {
                    if let result = response.result.value {
                        topics = APIManager.topicsFromResult(result)
                    }
                }
                completionHandler(topics)
        }
        .resume()
    }
    
    func allTopics(completionHandler: @escaping ([ChatTopic]) -> Void) {
        if allTopicsCache.count > 0 {
            Logger.default.logDebug("'allTopics' cache: \(allTopicsCache)")
            
            completionHandler(allTopicsCache)
            fetchAllTopics()
        } else {
            allTopics(completionHandler: completionHandler, cacheHandler: { [weak self] topics in
                if let strongSelf = self {
                    strongSelf.allTopicsCache = topics
                }
            })
        }
    }
    
    func fetchAllTopics() {
        allTopics(completionHandler: { topics in
        }, cacheHandler: { [weak self] topics in
            if let strongSelf = self {
                strongSelf.allTopicsCache = topics
            }
        })
    }
    
    private func allTopics(completionHandler: @escaping ([ChatTopic]) -> Void, cacheHandler: @escaping ([ChatTopic]) -> Void) {
        if !updatingAllTopicsCache {
            updatingAllTopicsCache = true
            sessionManager.request(apiURLWithPath("cs/topics/tree"),
                                   method: .get,
                                   encoding: JSONEncoding.default).validate().responseJSON { [weak self] response in
                                    
                                    var topics = [ChatTopic]()
                                    if response.error == nil {
                                        if let result = response.result.value {
                                            topics = APIManager.topicsFromResult(result)
                                        }
                                    }
                                    
                                    completionHandler(topics)
                                    cacheHandler(topics)
                                    
                                    if let strongSelf = self {
                                        strongSelf.updatingAllTopicsCache = false
                                    }
                }
                .resume()
        } else {
            Logger.default.logDebug("already updating 'all topics' cache, skipping")
        }
    }

    // MARK: - Response Parsing
    
    static func topicsFromResult(_ result: Any) -> [ChatTopic] {
        guard let dictionary = result as?  [String: Any],
            let topicDictionaries = dictionary["root"] as? [[String: Any]] else { return [] }
        
        let topics: [ChatTopic] = topicDictionaries.compactMap { topic in
            guard let title = topic["title"] as? String, let name = topic["topicName"] as? String else { return nil }
            return ChatTopic(title: title, name: name)
        }
        
        return topics
    }
    
}

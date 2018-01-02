//
//  AMBHTTPClient.swift
//  SnowChat
//
//  Created by Will Lisac on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire
import AMBClient

// FIXME: Hacked in networking client to make legacy AMB work
// Remove this class and fix the AMB HTTP client protocol

class AMBHTTPClient: NOWHTTPSessionClientProtocol {
    
    let baseURL: URL
    
    private let sessionManager: SessionManager
    
    init(sessionManager: SessionManager, baseURL: URL) {
        self.baseURL = baseURL
        self.sessionManager = sessionManager
    }
    
    func invalidateSessionCancelingTasks(_ cancelingTasks: Bool) {
        sessionManager.session.invalidateAndCancel()
    }
    
    func post(_ URLString: String,
              jsonParameters JSONParameters: Any,
              timeout: TimeInterval,
              success: @escaping (Any?) -> Void,
              failure: @escaping (Error?) -> Void) -> URLSessionDataTask? {
        
        guard let url = URL(string: URLString, relativeTo: baseURL),
            let params = JSONParameters as? [String: Any] else {
                DispatchQueue.main.async {
                    failure(nil)
                }
                return nil
        }
        
        let dataRequest = sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).validate().responseJSON { response in
            if let error = response.error {
                failure(error)
            } else {
                success(response.value)
            }
        }
        
        if let task = dataRequest.task as? URLSessionDataTask {
            return task
        }
        
        return nil
    }
    
}

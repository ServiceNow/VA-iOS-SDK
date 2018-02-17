//
//  InstanceConfiguration.swift
//  SnowChatAuthIntegrationTests
//
//  Created by Will Lisac on 2/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

/// Instance configuration
struct InstanceConfirugation {
    
    let username = "admin"
    let password = "admin"
    
    // swiftlint:disable:next force_unwrapping
    fileprivate let instanceURL = URL(string: "http://localhost:8080")!
    
    var accessToken: String?
    
    fileprivate let itilUsername = "itil"
    fileprivate let itilPassword = "itil"
    
}

/// Auth headers
extension InstanceConfirugation {
    
    var accessTokenAuthHeaders: HTTPHeaders {
        // swiftlint:disable:next force_unwrapping
        return ["Authorization" : "Bearer \(accessToken!)"]
    }
    
    var basicAuthHeaders: HTTPHeaders {
        return basicAuthHeaders(username: username, password: password)
    }
    
    var invalidBasicAuthHeaders: HTTPHeaders {
        return ["Authorization" : "Basic nope"]
    }
    
    var invalidAccessTokenAuthHeaders: HTTPHeaders {
        return ["Authorization" : "Bearer nope"]
    }
    
    var itilBasicAuthHeaders: HTTPHeaders {
        return basicAuthHeaders(username: itilUsername, password: itilPassword)
    }
    
    private func basicAuthHeaders(username: String, password: String) -> HTTPHeaders {
        let credentials = "\(username):\(password)"
        let data = credentials.data(using: .utf8)
        let base64Auth = data?.base64EncodedString() ?? ""
        let authValue = "Basic \(base64Auth)"
        return ["Authorization" : authValue]
    }
}

/// URL construction
extension InstanceConfirugation {
    
    func apiURLWithPath(_ path: String, version: Int = 1) -> URL {
        return urlWithPath("/api/now/v\(version)").appendingPathComponent(path)
    }
    
    func urlWithPath(_ path: String) -> URL {
        return instanceURL.appendingPathComponent(path)
    }
    
}

/// URL constants
extension InstanceConfirugation {
    
    var privateRESTAPI: URL {
        return apiURLWithPath("mobile/app_bootstrap/post_auth")
    }
    
    var publicRESTAPI: URL {
        return apiURLWithPath("mobile/app_bootstrap/pre_auth")
    }

    var privateUIAPI: URL {
        return urlWithPath("task_list.do")
    }
    
    var angularAPI: URL {
        return urlWithPath("angular.do")
    }
    
}

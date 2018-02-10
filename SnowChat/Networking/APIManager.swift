//
//  APIManager.swift
//  SnowChat
//
//  Created by Will Lisac on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage
import AMBClient

class APIManager: NSObject {
    
    internal let instance: ServerInstance
    
    // Each API Manager instance has a private session. That's why we use an ephemeral configuration.
    internal let sessionManager = SessionManager(configuration: .ephemeral)
    
    internal let reachabilityManager = NetworkReachabilityManager()
    
    internal weak var transportListener: TransportStatusListener?
    
    private(set) internal lazy var imageDownloader: ImageDownloader = {
        // TODO: Find out if images need to be authenticated. If not we don't have to use our sessionManager.
        // IF we do have to use a sessionManager - there's behavior where ImageDownloader sets `startRequestsImmediately` flag of session manager to `false`
        // and causes bug, where request are not being resumed. That breaks all our API requests.
        return ImageDownloader()
    }()
    
    internal let ambClient: AMBClient
    
    init(instance: ServerInstance, transportListener: TransportStatusListener? = nil) {
        self.instance = instance
        self.transportListener = transportListener
        
        ambClient = AMBClient(sessionManager: sessionManager, baseURL: instance.instanceURL)

        super.init()

        subscribeToAppStateChanges()
        listenForReachabilityChanges()
        listenForAMBConnectionChanges()
    }
    
    enum APIManagerError: Error {
        case loginError(message: String)
    }
    
    // FIXME: Support actual log in methods
    
    func logIn(username: String, password: String, completionHandler: @escaping (Error?) -> Void) {
        sessionManager.adapter = AuthHeadersAdapter(username: username, password: password)
        
        sessionManager.request(apiURLWithPath("mobile/app_bootstrap/post_auth"),
                               method: .get,
                               parameters: nil,
                               encoding: JSONEncoding.default,
                               headers: nil)
            .validate()
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                
                var loginError: APIManagerError?
                
                switch response.result {
                case .success:
                    strongSelf.ambClient.connect()
                case .failure(let error):
                    loginError = APIManagerError.loginError(message: "Login failed: \(error.localizedDescription)")
                }
                completionHandler(loginError)
        }
    }
    
    private func listenForReachabilityChanges() {
        guard let reachabilityManager = reachabilityManager else { return }
        
        reachabilityManager.startListening()
        
        reachabilityManager.listener = { [weak self] status in
            guard let strongSelf = self else { return }
            if reachabilityManager.isReachable {
                strongSelf.ambClient.networkReachable()
                
                // FIXME: should only send this from AMB notification, but it is not working quite right
                strongSelf.transportListener?.transportDidBecomeAvailable()
            } else {
                strongSelf.ambClient.networkUnreachable()
                
                // FIXME: should only send this from AMB notification, but it is not working quite right
                strongSelf.transportListener?.transportDidBecomeUnavailable()
            }
        }
    }
    
    private func subscribeToAppStateChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActiveNotification(_:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    @objc internal func applicationWillResignActiveNotification(_ notification: Notification) {
        ambClient.applicationWillResignActiveNotification()
    }
    
    @objc internal func applicationDidBecomeActiveNotification(_ notification: Notification) {
        ambClient.applicationDidBecomeActiveNotification()
    }
    
    private func listenForAMBConnectionChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(ambConnectionStatusChange(_:)), name: NSNotification.Name.NOWFayeClientConnectionStatusDidChange, object: nil)
    }
    
    @objc func ambConnectionStatusChange(_ notification: Notification) {
        if let transportListener = transportListener,
           let info = notification.userInfo,
           let statusValue = info[NOWFayeClientConnectionStatusDidChangeNotificationStatusKey] as? UInt,
           let status = NOWFayeClientStatus(rawValue: statusValue) {
            
            switch status {
            case .connected:
                transportListener.transportDidBecomeAvailable()
            case .disconnected:
                transportListener.transportDidBecomeUnavailable()
            default:
                Logger.default.logInfo("AMB connection notification: \(status)")
            }
        }
    }
}

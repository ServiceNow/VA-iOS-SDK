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
import SNOWAMBClient

enum APIManagerError: Error {
    case loginError(message: String)
    case invalidToken(message: String)
}

class APIManager: NSObject {
    
    private enum AuthStatus {
        case loggedIn(User)
        case loggedOut(User?)
    }
    
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
    
    internal let ambClient: SNOWAMBClient

    private var authStatus: AuthStatus
    
    // MARK: - Initialization
    
    init(instance: ServerInstance, transportListener: TransportStatusListener? = nil) {
        self.instance = instance
        self.transportListener = transportListener
        self.authStatus = .loggedOut(nil)
        
        ambClient = SNOWAMBClient(httpClient: AMBHTTPClient(sessionManager: sessionManager, baseURL: instance.instanceURL))

        super.init()
        
        ambClient.delegate = self

        subscribeToAppStateChanges()
        listenForReachabilityChanges()
        setupSessionTaskAuthListener()
    }
    
    // MARK: - Log In
    
    func prepareUserSession(token: OAuthToken, completion: @escaping (Result<User>) -> Void) {
        // TODO: Should we only clear some session cookies instead of all?
        clearAllCookies()
        
        sessionManager.adapter = AuthHeadersAdapter(instanceURL: instance.instanceURL, accessToken: token)
        
        // FIXME: Don't use mobile app APIs. Need to move to this API when it's ready: ui/user/current_user
        sessionManager.request(apiURLWithPath("mobile/app_bootstrap/post_auth"),
                               method: .get,
                               parameters: nil,
                               encoding: JSONEncoding.default,
                               headers: nil)
            .validate()
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                
                if let error = response.error {
                    let loginError: APIManagerError
                    if let response = response.response, response.statusCode == 401 {
                        loginError = APIManagerError.invalidToken(message: "Login failed: \(error.localizedDescription)")
                    } else {
                        loginError = APIManagerError.loginError(message: "Login failed: \(error.localizedDescription)")
                    }
                    completion(.failure(loginError))
                    return
                }
                
                // TODO: Need a better solution for response parsing. Custom mappings?
                let dictionary = response.result.value as? [String : Any] ?? [:]
                let result = dictionary["result"] as? [String : Any] ?? [:]
                let resources = result["resources"] as? [String : Any] ?? [:]
                let userDictionary = resources["current_user"] as? [String : Any] ?? [:]
                
                guard let user = User(dictionary: userDictionary) else {
                    completion(.failure(APIManagerError.loginError(message: "Invalid User")))
                    return
                }
                
                strongSelf.authStatus = .loggedIn(user)
                strongSelf.ambClient.connect()
                
                completion(.success(user))
        }
    }
    
    private func clearAllCookies() {
        guard let cookieStorage = sessionManager.session.configuration.httpCookieStorage else { return }
        cookieStorage.cookies?.forEach { (cookie) in
            cookieStorage.deleteCookie(cookie)
        }
    }
    
    // MARK: - Auth Listener
    
    private func setupSessionTaskAuthListener() {
        sessionManager.delegate.taskDidComplete = { session, task, error in
            
            guard let response = task.response as? HTTPURLResponse, response.statusCode == 401 else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.invalidateAuthentication()
            }
            
        }
    }
    
    private func invalidateAuthentication() {
        guard case let .loggedIn(user) = authStatus else { return }
        
        authStatus = .loggedOut(user)
        
        transportListener?.apiManagerAuthenticationDidBecomeInvalid(self)
    }
    
    // MARK: - Transport Listener
    
    private func listenForReachabilityChanges() {
        guard let reachabilityManager = reachabilityManager else { return }
        
        reachabilityManager.startListening()
        
        reachabilityManager.listener = { [weak self] status in
            guard let strongSelf = self else { return }
            if reachabilityManager.isReachable {
                strongSelf.ambClient.isPaused = false
                
                // FIXME: should only send this from AMB notification, but it is not working quite right
                strongSelf.transportListener?.apiManagerTransportDidBecomeAvailable(strongSelf)
            } else {
                strongSelf.ambClient.isPaused = true
                
                // FIXME: should only send this from AMB notification, but it is not working quite right
                strongSelf.transportListener?.apiManagerTransportDidBecomeUnavailable(strongSelf)
            }
        }
    }
    
    private func subscribeToAppStateChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActiveNotification(_:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    @objc internal func applicationWillResignActiveNotification(_ notification: Notification) {
        ambClient.isPaused = true
    }
    
    @objc internal func applicationDidBecomeActiveNotification(_ notification: Notification) {
        ambClient.isPaused = false
    }
    
}

// MARK: - AMB Transport

extension APIManager {
    
    func sendMessage(_ message: [String: Any], toChannel channel: String) {
        ambClient.publishMessage(message, toChannel: channel, withExtension:[:],
                                  completion: { (result) in
                                    switch result {
                                    case .success:
                                        Logger.default.logInfo("published message successfully")
                                    //TODO: Implement handler here
                                    case .failure:
                                        Logger.default.logInfo("failed to publish message")
                                    //TODO: same
                                    }
        })
    }
    
    func sendMessage<T>(_ message: T, toChannel channel: String, encoder: JSONEncoder) where T: Encodable {
        do {
            let jsonData = try encoder.encode(message)
            if let dict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                
                if Logger.default.enabled, let jsonString = String(data: jsonData, encoding: .utf8) {
                    Logger.default.logInfo("Publishing to AMB Channel: \(channel): \(jsonString)")
                }
                
                sendMessage(dict, toChannel: channel)
            }
        } catch let err {
            Logger.default.logError("Error publishing: \(err)")
        }
    }
    
    func subscribe(_ channelName: String, messages messageHandler: @escaping SNOWAMBMessageHandler) -> SNOWAMBSubscription {
        let subscription: SNOWAMBSubscription = ambClient.subscribe(channel: channelName, messageHandler: { (result, subscription) in
            switch result {
            case .success:
                if let message = result.value {
                    Logger.default.logInfo("Incoming AMB Message: \(message.jsonDataString)")
                    messageHandler(result, subscription)
                }
            case .failure:
                messageHandler(result, subscription)
            }
        })
        return subscription
    }

}

// MARK: - AMB Delegate

extension APIManager: SNOWAMBClientDelegate {
    
    func didConnect(client: SNOWAMBClient) {}
    func didDisconnect(client: SNOWAMBClient) {}
    func didSubscribe(client: SNOWAMBClient, toChannel: String) {}
    func didUnsubscribe(client: SNOWAMBClient, fromchannel: String) {}
    func didReceive(client: SNOWAMBClient, message: SNOWAMBMessage, fromChannel channel: String) {}
    func didGlideStatusChange(client: SNOWAMBClient, status: SNOWAMBGlideStatus) {}
    
    func didFail(client: SNOWAMBClient, withError error: SNOWAMBError) {
        Logger.default.logInfo("AMB client error: \(error.localizedDescription)")
    }

    func didClientStatusChange(client: SNOWAMBClient, status: SNOWAMBClientStatus) {
        if let transportListener = transportListener {
            switch status {
            case .connected:
                transportListener.apiManagerTransportDidBecomeAvailable(self)
            case .disconnected:
                transportListener.apiManagerTransportDidBecomeUnavailable(self)
            default:
                Logger.default.logInfo("AMB connection notification: \(status)")
            }
        }
    }
    
}

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
import WebKit

enum APIManagerError: Error {
    case loginError(message: String)
    case invalidToken(message: String)
    case invalidUser(message: String)
}

class APIManager: NSObject, AMBClientDelegate {
    
    internal enum AuthStatus {
        case loggedIn(User)
        case loggedOut(User?)
    }
    
    internal enum AMBPauseReason {
        case reachability
        case appBackgrounded
        case repairingSession
        case loggedOut
        case noView
    }
    
    internal let instance: ServerInstance
    
    internal let sessionManager: SessionManager = {
        // Each API Manager instance has a private session. That's why we use an ephemeral configuration.
        let sessionManager = SessionManager(configuration: .ephemeral)

        // We also explicitly set startRequestImmediately to false since the ImageDownloder will do this anyway,
        // and we want consistent behavior
        sessionManager.startRequestsImmediately = false
        
        return sessionManager
    }()
    
    internal let reachabilityManager = NetworkReachabilityManager()
    
    internal weak var transportListener: TransportStatusListener?
    
    private(set) internal lazy var imageDownloader: ImageDownloader = {
        // use our session manager so we do not create a new session for images
        return ImageDownloader(sessionManager: sessionManager)
    }()
    
    internal let ambClient: AMBClient
    private var ambPauseReasons = Set<AMBPauseReason>()
    private var ambTransportAvailable: Bool = false
    
    private let webViewProcessPool = WKProcessPool()
    private let webViewDataStorage = WKWebsiteDataStore.nonPersistent()
    
    internal var webViewConfiguration: WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        configuration.processPool = webViewProcessPool
        configuration.websiteDataStore = webViewDataStorage
        return configuration
    }
    
    internal private(set) var authStatus: AuthStatus
    
    // MARK: - Initialization
    
    init(instance: ServerInstance, transportListener: TransportStatusListener? = nil) {
        self.instance = instance
        self.transportListener = transportListener
        self.authStatus = .loggedOut(nil)
        
        ambClient = AMBClient(httpClient: AMBHTTPClient(sessionManager: sessionManager, baseURL: instance.instanceURL))

        super.init()
        
        ambClient.delegate = self

        subscribeToAppStateChanges()
        listenForReachabilityChanges()
        setupSessionTaskAuthListener()
    }
    
    // MARK: - Log In
    
    func prepareUserSession(token: OAuthToken, completion: @escaping (Result<User>) -> Void) {
        guard case let .loggedOut(currentUser) = authStatus else {
            fatalError("Attempted to prepare a user session while the API Manager is already logged in. This is not allowed.")
        }
        
        let isFirstLogIn = (currentUser == nil)
        
        // TODO: Should we only clear some session cookies instead of all?
        clearAllCookies()
        
        let authInterceptor = AuthInterceptor(instance: instance, token: token)
        sessionManager.adapter = authInterceptor
        sessionManager.retrier = authInterceptor
        
        sessionManager.request(apiURLWithPath("ui/user/current_user"), method: .get)
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
                let userDictionary = dictionary["result"] as? [String : Any] ?? [:]
                
                guard let user = User(dictionary: userDictionary) else {
                    completion(.failure(APIManagerError.invalidUser(message: "Invalid user information.")))
                    return
                }
                
                guard currentUser == nil || user.sysId == currentUser?.sysId else {
                    completion(.failure(APIManagerError.invalidUser(message: "Attempted to reauthenticate as a different user.")))
                    return
                }
                
                strongSelf.authStatus = .loggedIn(user)
                
                if isFirstLogIn {
                    strongSelf.ambClient.connect()
                } else {
                    strongSelf.removeAMBPauseReason(.loggedOut)
                }
                
                completion(.success(user))
        }
        .resume()
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
        
        addAMBPauseReason(.loggedOut)
        
        transportListener?.apiManagerAuthenticationDidBecomeInvalid(self)
    }
    
    // MARK: - Transport Listener
    
    private func updateAMBTransportAvailabilityIfNeeded() {
        let available = (!ambClient.isPaused) && (ambClient.clientStatus == .connected)
        
        guard available != ambTransportAvailable else { return }
        
        ambTransportAvailable = available
        
        if available {
            transportListener?.apiManagerTransportDidBecomeAvailable(self)
        } else {
            transportListener?.apiManagerTransportDidBecomeUnavailable(self)
        }
        
        Logger.default.logInfo("Updated transport availability: \(available ? "available" : "unavailable")")
    }
    
    private func listenForReachabilityChanges() {
        guard let reachabilityManager = reachabilityManager else { return }
        
        reachabilityManager.startListening()
        
        reachabilityManager.listener = { [weak self] status in
            guard let strongSelf = self else { return }
            
            if reachabilityManager.isReachable {
                strongSelf.removeAMBPauseReason(.reachability)
            } else {
                strongSelf.addAMBPauseReason(.reachability)
            }
        }
    }
    
    private func subscribeToAppStateChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc internal func applicationDidEnterBackground(_ notification: Notification) {
        addAMBPauseReason(.appBackgrounded)
    }
    
    @objc internal func applicationWillEnterForeground(_ notification: Notification) {
        removeAMBPauseReason(.appBackgrounded)
    }
    
    // MARK: - AMB Pausing
    
    @discardableResult internal func addAMBPauseReason(_ reason: AMBPauseReason) -> Bool {
        Logger.default.logInfo("Adding AMB pause reason: \(reason)")
        
        let inserted = ambPauseReasons.insert(reason).inserted
        if !ambClient.isPaused {
            Logger.default.logInfo("Pausing AMB")
            
            ambClient.isPaused = true
            updateAMBTransportAvailabilityIfNeeded()
        }
        return inserted
    }
    
    @discardableResult internal func removeAMBPauseReason(_ reason: AMBPauseReason) -> Bool {
        Logger.default.logInfo("Removing AMB pause reason: \(reason)")
        
        let removedReason = ambPauseReasons.remove(reason)
        if ambPauseReasons.isEmpty && ambClient.isPaused {
            Logger.default.logInfo("Unpausing AMB")
            
            ambClient.isPaused = false
            updateAMBTransportAvailabilityIfNeeded()
        }
        return removedReason != nil
    }
    
    // MARK: - AMB Timeout
    
    private func handleAMBSessionTimeout() {
        guard case AuthStatus.loggedIn = authStatus else { return }
        
        guard addAMBPauseReason(.repairingSession) else { return }
        
        Logger.default.logInfo("Attempting to repair session for AMB")
        
        // Use any REST API to try and renew our session cookies
        sessionManager.request(apiURLWithPath("ui/user/current_user"), method: .get)
            .validate()
            .responseJSON { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                strongSelf.removeAMBPauseReason(.repairingSession)
                
                // Any error here invalidates authentication
                // This is overly aggressive, but it reduces complexity
                // Note that if we get a 401, the task handler will have already triggered auth invalidation
                // This is just a catch all – without it, I'm not sure what our "next step" should be to try and recover AMB
                // Consider revisiting this approach in the future if we think it's too aggressive
                if response.error != nil {
                    strongSelf.invalidateAuthentication()
                    Logger.default.logInfo("Failed to repair auth session for AMB")
                } else {
                    Logger.default.logInfo("Successfully repaired auth session for AMB")
                }
        }
        .resume()
    }
    
    // MARK: - AMB Listener
    
    func ambClientDidConnect(_ client: AMBClient) {}
    func ambClientDidDisconnect(_ client: AMBClient) {}
    func ambClient(_ client: AMBClient, didSubscribeToChannel channel: String) {}
    func ambClient(_ client: AMBClient, didUnsubscribeFromChannel channel: String) {}
    func ambClient(_ client: AMBClient, didReceiveMessage: AMBMessage, fromChannel channel: String) {}
    
    func ambClient(_ client: AMBClient, didReceiveGlideStatus status: AMBGlideStatus) {
        guard let sessionStatus = status.sessionStatus, sessionStatus == .loggedOut else {
            return
        }
        
        Logger.default.logInfo("Received AMB logged out session status")
        
        handleAMBSessionTimeout()
    }
    
    func ambClient(_ client: AMBClient, didFailWithError error: AMBError) {
        Logger.default.logInfo("AMB client error: \(error.localizedDescription)")
    }
    
    func ambClient(_ client: AMBClient, didChangeClientStatus status: AMBClientStatus) {
        updateAMBTransportAvailabilityIfNeeded()
        Logger.default.logInfo("AMB connection notification: \(status)")
    }
    
}

//
//  ChatService.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public enum ChatServiceError: Error {
    case invalidCredentials
    case noSession(Error?)
}

public final class ChatService {
    
    // swiftlint:disable:next weak_delegate
    public weak var delegate: ChatServiceDelegate?
    
    public var isConnected: Bool {
        switch chatterbox.apiManager.authStatus {
        case .loggedIn:
            return true
        default:
            return false
        }
    }
    
    private let chatterbox: Chatterbox
    
    private var isInitializing: Bool = false
    
    // FIXME: What is the vendor ID for? Who defines this?
    private let vendor = ChatVendor(name: "ServiceNow", vendorId: "c2f0b8f187033200246ddd4c97cb0bb9")
    
    public init(instanceURL: URL, delegate: ChatServiceDelegate?) {
        let instance = ServerInstance(instanceURL: instanceURL)
        self.chatterbox = Chatterbox(instance: instance)
        self.delegate = delegate
        self.chatterbox.chatAuthListeners.addListener(self)

        ChatService.defaultLogLevels()
    }
    
    deinit {
        Logger.default.logFatal("ChatService deinit")
    }
    
    public static func loggers() -> [Logger] {
        return [Logger.logger(for: "Chatterbox"),
                Logger.logger(for: "ChatDataController"),
                Logger.default]
    }
    
    public static func defaultLogLevels() {
        // Set default log levels for debugging
        Logger.logger(for: "Chatterbox").logLevel = .debug
        Logger.logger(for: "ChatDataController").logLevel = .debug
        Logger.default.logLevel = .debug
    }
    
    // start a chat, providing a view-controller for the application to manage
    public func chatViewController(modal: Bool = false) -> ChatViewController {
        guard !modal else {
            // FIXME: Handle modal case
            fatalError("Not yet implemented.")
        }

        let viewController = ChatViewController(chatterbox: chatterbox)
        return viewController
    }
    
    public func establishUserSession(token: OAuthToken, userContextData contextData: Codable? = nil, completion: @escaping (ChatServiceError?) -> Void) {
        if isInitializing {
            fatalError("Only one initialization can be performed at a time.")
        }
        
        isInitializing = true
        
        if isConnected {
            chatterbox.restoreUserSession { [weak self] result in
                
                self?.isInitializing = false
                
                switch result {
                case let .success(message):
                    Logger.default.logDebug("Session Updated: \(message)")
                    completion(nil)
                case let .failure(error):
                    Logger.default.logDebug("Session failed to update: \(error.localizedDescription)")
                    completion(chatError(fromError: error))
                }
            }
        } else {
            chatterbox.establishUserSession(vendor: vendor, token: token, userContextData: contextData) { [weak self] result in
                
                self?.isInitializing = false
                
                switch result {
                case let .success(message):
                    Logger.default.logDebug("Session Initialized: \(message)")
                    completion(nil)
                case let .failure(error):
                    Logger.default.logDebug("Session failed to initialize: \(error.localizedDescription)")
                    completion(chatError(fromError: error))
                }
            }
        }
        
        func chatError(fromError error: Error) -> ChatServiceError {
            if case APIManagerError.invalidToken = error {
                return ChatServiceError.invalidCredentials
            }
            return ChatServiceError.noSession(error)
        }
    }
}

extension ChatService: ChatAuthListener {
    
    func chatterboxAuthenticationDidBecomeInvalid(_ chatterbox: Chatterbox) {
        delegate?.chatServiceAuthenticationDidBecomeInvalid(self)
    }
    
}

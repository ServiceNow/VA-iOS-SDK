//
//  HomeViewController.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import SnowChat

class HomeViewController: UIViewController, ChatServiceDelegate {
    
    private var chatService: ChatService?

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SnowKangaroo"
        
        setupNavigationBarButtons()
        setupAuthNotificationObserving()
    }
    
    // MARK: - UI Setup
    
    private func setupNavigationBarButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Log Out", comment: ""), style: .plain, target: self, action: #selector(logOutButtonTapped(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "🐞", style: .plain, target: self, action: #selector(debugButtonTapped(_:)))
    }
    
    // MARK: - Chat
    
    private func startChat() {
        guard let instanceURL = InstanceSettings.shared.instanceURL,
            let credential = InstanceSettings.shared.credential else {
                return
        }
        
        let instance = ServerInstance(instanceURL: instanceURL)
        let chatService = ChatService(instance: instance, delegate: self)
        self.chatService = chatService
        
        navigationController?.pushViewController(chatService.chatViewController(), animated: true)
        
        establishChatSession(credential: credential, logOutOnAuthFailure: false)
    }
    
    private func establishChatSession(credential: OAuthCredential, logOutOnAuthFailure: Bool) {
        guard let chatService = chatService else { return }
        
        let token = credential.idToken ?? credential.accessToken
        
        chatService.establishUserSession(token: token) { [weak self] (error) in
            if let error = error {
                if case ChatServiceError.invalidCredentials = error {
                    if logOutOnAuthFailure {
                        self?.navigationController?.popToRootViewController(animated: true)
                        self?.postLogOutNotification()
                    } else {
                        self?.postAuthenticationDidBecomeInvalidNotification()
                    }
                } else {
                    self?.presentError(error)
                }
            }
        }
    }
    
    // MARK: - Button Actions
    
    @objc func chatButtonTapped(_ sender: Any) {
        startChat()
    }
    
    @objc func logOutButtonTapped(_ sender: Any) {
        postLogOutNotification()
    }
    
    @objc func debugButtonTapped(_ sender: Any) {
        let debugController = DebugViewController.fromStoryboard()
        navigationController?.pushViewController(debugController, animated: true)
    }
    
    // MARK: - Error Handling
    
    private func presentError(_ error: Error) {
        let alertTitle = NSLocalizedString("Error", comment: "")
        let alert = UIAlertController(title: alertTitle, message: error.localizedDescription, preferredStyle: .alert)
        
        let dismissTitle = NSLocalizedString("Dismiss", comment: "")
        let dismissAction = UIAlertAction(title: dismissTitle, style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        alert.addAction(dismissAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Auth Notifications
    
    private func setupAuthNotificationObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSNAuthenticationDidBecomeValidNotification(_:)),
                                               name: .SNAuthenticationDidBecomeValid,
                                               object: nil)
    }
    
    @objc private func handleSNAuthenticationDidBecomeValidNotification(_ notification: Notification) {
        guard let credential = InstanceSettings.shared.credential else {
            return
        }
        
        // Repair existing chat service with new credential
        establishChatSession(credential: credential, logOutOnAuthFailure: true)
    }
    
    private func postLogOutNotification() {
        NotificationCenter.default.post(name: .LogOut, object: nil)
    }
    
    private func postAuthenticationDidBecomeInvalidNotification() {
        NotificationCenter.default.post(name: .SNAuthenticationDidBecomeInvalid, object: nil)
    }
    
    // MARK: - ChatServiceDelegate
    
    func chatServiceAuthenticationDidBecomeInvalid(_ chatService: ChatService) {
        postAuthenticationDidBecomeInvalidNotification()
    }

}

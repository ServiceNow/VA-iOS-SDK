//
//  HomeViewController.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import SnowChat

class HomeViewController: UIViewController, ChatServiceDelegate, UINavigationControllerDelegate {
    
    private var chatService: ChatService?
    
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet weak var forceSessionSwitch: UISwitch!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SnowKangaroo"
        
        setupChatService()
        setupNavigationBarButtons()
        setupAuthNotificationObserving()
        
        navigationController?.delegate = self
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController === self {
            chatService?.pauseNetwork()
            NSLog("Pausing network activity while no chat view is showing...")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupStatusLabel()

        chatButton.isEnabled = true
        
        forceSessionSwitch.isOn = false
        
        if chatService?.isConnected ?? false {
            forceSessionSwitch.isEnabled = true
        } else {
            forceSessionSwitch.isOn = true
            forceSessionSwitch.isEnabled = false
        }
    }
    
    private func setupChatLoggingLevels() {
        ChatService.loggers().forEach { (logger) in
            switch logger.category {
            case "Chatterbox", "DataController":
                logger.logLevel = .error
            default:
                logger.logLevel = .fatal
            }
        }
    }
    
    // MARK: - UI Setup
    
    private func setupChatService() {
        guard let instanceURL = InstanceSettings.shared.instanceURL else {
            NSLog("No instance URL defined: cannot setup ChatService")
            return
        }
        
        let chatService = ChatService(instanceURL: instanceURL, delegate: self)
        self.chatService = chatService
        
        setupChatLoggingLevels()
    }
    
    private func setupNavigationBarButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Log Out", comment: ""), style: .plain, target: self, action: #selector(logOutButtonTapped(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "🐞", style: .plain, target: self, action: #selector(debugButtonTapped(_:)))
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.75)
    }

    private func setupStatusLabel() {
        if let instanceURL = InstanceSettings.shared.instanceURL, let host = instanceURL.host {
            statusLabel.text = "Instance: \(host)"
        }
    }
    
    // MARK: - Chat
    
    private func startChat() {
        guard let credential = InstanceSettings.shared.credential else {
            return
        }

        chatButton.isEnabled = false
        
        if forceSessionSwitch.isOn {
            setupChatService()
            statusLabel.text = "Establishing new Chat Session..."
        } else {
            statusLabel.text = "Resuming existing Chat Session..."
        }
        
        establishChatSession(credential: credential, logOutOnAuthFailure: true)
    }
    
    private func establishChatSession(credential: OAuthCredential, logOutOnAuthFailure: Bool) {
        guard let chatService = chatService else { return }
        
        NSLog("Resuming networking and establishing user session")
        chatService.resumeNetwork()
        
        let token = credential.idToken ?? credential.accessToken

        chatService.establishUserSession(token: token, userContextData: UserDefinedContextData()) { [weak self] (error) in
            if let error = error {
                self?.errorInUserSession(error, logOutOnAuthFailure)
            } else {
                self?.navigationController?.pushViewController(chatService.chatViewController(), animated: true)
            }
        }
    }

    private func errorInUserSession(_ error: ChatServiceError, _ logOutOnAuthFailure: Bool = false) {
        if case ChatServiceError.invalidCredentials = error {
            if logOutOnAuthFailure {
                postLogOutNotification()
            } else {
                postAuthenticationDidBecomeInvalidNotification()
            }
        } else {
            presentError(error)
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

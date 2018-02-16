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
        
        chatService.establishUserSession(token: credential.accessToken) { [weak self] (error) in
            if let error = error {
                if case ChatServiceError.invalidCredentials = error {
                    self?.postLogOutNotification()
                } else {
                    self?.presentError(error)
                }
            } else {
                self?.navigationController?.pushViewController(chatService.chatViewController(), animated: true)
            }
        }
    }
    
    // MARK: - Actions
    
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
        let alert = UIAlertController()
        alert.message = error.localizedDescription
        alert.title = NSLocalizedString("Error", comment: "")
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Auth
    
    private func postLogOutNotification() {
        NotificationCenter.default.post(name: .SNAuthenticationDidBecomeInvalid, object: nil)
    }
    
    // MARK: - ChatServiceDelegate
    
    func chatServiceAuthenticationDidBecomeInvalid(_ chatService: ChatService) {
        // FIXME: Try and refresh the access token and call establishUserSession again
        postLogOutNotification()
    }

}

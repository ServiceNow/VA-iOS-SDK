//
//  RootViewController.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import SnowChat

class RootViewController: UIViewController, LogInViewControllerDelegate {
    
    private var viewDidAppearOnce = false
    private var authRefreshManager: OAuthManager?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        setupAuthNotificationObserving()
        setupRootController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewDidAppearOnce {
            viewDidAppearOnce = true
            presentAuthViewControllerIfNeeded(animated: animated)
        }
    }
    
    // MARK: - Setup
    
    private func setupRootController() {
        let debugController = HomeViewController()
        let controller = UINavigationController(rootViewController: debugController)
        
        controller.willMove(toParentViewController: self)
        addChildViewController(controller)
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.view.frame = view.bounds
        view.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
    }
    
    // MARK: - Auth Notifications
    
    private func setupAuthNotificationObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSNAuthenticationDidBecomeInvalidNotification(_:)),
                                               name: .SNAuthenticationDidBecomeInvalid,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLogOutNotification(_:)),
                                               name: .LogOut,
                                               object: nil)
    }
    
    @objc private func handleLogOutNotification(_ notification: Notification) {
        logOut()
    }
    
    @objc private func handleSNAuthenticationDidBecomeInvalidNotification(_ notification: Notification) {
        attemptToRepairCredentialsOrLogOut()
    }
    
    // MARK: - Auth
    
    private func logOut() {
        // Remove existing credential
        InstanceSettings.shared.credential = nil
        
        presentAuthViewControllerIfNeeded(animated: true)
    }
    
    private func attemptToRepairCredentialsOrLogOut() {
        guard let instanceURL = InstanceSettings.shared.instanceURL,
            let credential = InstanceSettings.shared.credential,
            let refreshToken = credential.refreshToken,
            let authProvider = InstanceSettings.shared.authProvider else {
                logOut()
                return
        }
        
        // Attempt to refresh credential
        let authManager = OAuthManager(authProvider: authProvider, instanceURL: instanceURL)
        self.authRefreshManager = authManager
        
        authManager.authenticate(refreshToken: refreshToken) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            guard case let .success(credential) = result else {
                strongSelf.logOut()
                return
            }
            
            InstanceSettings.shared.credential = credential
            
            NotificationCenter.default.post(name: .SNAuthenticationDidBecomeValid, object: nil)
        }
    }
    
    private func presentAuthViewControllerIfNeeded(animated: Bool) {
        let instanceURL = InstanceSettings.shared.instanceURL
        let credential = InstanceSettings.shared.credential
        
        guard instanceURL == nil || credential == nil else {
            return
        }
        
        let logInViewController = LogInViewController(instanceURL: instanceURL)
        logInViewController.delegate = self
        let navViewController = UINavigationController(rootViewController: logInViewController)
        present(navViewController, animated: animated)
    }
    
    // MARK: - LogInViewControllerDelegate
    
    func logInViewControllerDidAuthenticate(_ controller: LogInViewController, instanceURL: URL, credential: OAuthCredential, authProvider: AuthProvider) {
        InstanceSettings.shared.instanceURL = instanceURL
        InstanceSettings.shared.credential = credential
        InstanceSettings.shared.authProvider = authProvider
        
        // Reset root VC after log in
        setupRootController()
        
        dismiss(animated: true)
    }

}

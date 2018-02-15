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
    
    // MARK: - Notifications
    
    private func setupAuthNotificationObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSNAuthenticationDidBecomeInvalidNotification(_:)),
                                               name: .SNAuthenticationDidBecomeInvalid,
                                               object: nil)
    }
    
    @objc private func handleSNAuthenticationDidBecomeInvalidNotification(_ notification: Notification) {
        // Remove existing credential
        InstanceSettings.shared.credential = nil
        
        presentAuthViewControllerIfNeeded(animated: true)
    }
    
    // MARK: - Auth
    
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
    
    func logInViewControllerDidAuthenticate(_ controller: LogInViewController, instanceURL: URL, credential: OAuthCredential) {
        InstanceSettings.shared.instanceURL = instanceURL
        InstanceSettings.shared.credential = credential
        
        dismiss(animated: true)
    }

}

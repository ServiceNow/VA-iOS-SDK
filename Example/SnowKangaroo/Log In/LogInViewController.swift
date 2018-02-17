//
//  LogInViewController.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/6/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

protocol LogInViewControllerDelegate: class {
    func logInViewControllerDidAuthenticate(_ controller: LogInViewController, instanceURL: URL, credential: OAuthCredential)
}

class LogInViewController: UIViewController {
    
    private var authManager: AuthManager?
    private var initialInstanceURL: URL?
    
    weak var delegate: LogInViewControllerDelegate?

    @IBOutlet private weak var instanceTextField: UITextField!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    private lazy var logInButton: UIBarButtonItem = {
        return UIBarButtonItem(title: NSLocalizedString("Log In", comment: ""),
                               style: .done,
                               target: self,
                               action: #selector(logInButtonTapped(_:)))
    }()
    
    // MARK: - Initialization
    
    convenience init(instanceURL: URL? = nil) {
        self.init()
        initialInstanceURL = instanceURL
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Log In", comment: "")
        navigationItem.rightBarButtonItem = logInButton
        
        instanceTextField.text = initialInstanceURL?.absoluteString
    }
    
    // MARK: - UI Updates
    
    private func updateUI(isLoading: Bool) {
        logInButton.isEnabled = !isLoading
        usernameTextField.isEnabled = !isLoading
        passwordTextField.isEnabled = !isLoading
        instanceTextField.isEnabled = !isLoading
        isLoading ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
    }
    
    // MARK: - Actions
    
    @objc private func logInButtonTapped(_ sender: Any) {
        view.endEditing(true)

        logIn()
    }
    
    // MARK: - Log In
    
    private func logIn() {
        guard let username = usernameTextField.text,
            let password = passwordTextField.text,
            let instanceText = instanceTextField.text,
            let instanceURL = URL(serverInstanceString: instanceText) else {
                updateUI(isLoading: false)
                return
        }
        
        updateUI(isLoading: true)
        
        let authManager = AuthManager(instanceURL: instanceURL)
        
        self.authManager = authManager
        
        authManager.logIn(username: username, password: password) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.updateUI(isLoading: false)
            
            guard case let .success(credential) = result else {
                // swiftlint:disable:next force_unwrapping
                self?.presentAlert(for: result.error!)
                return
            }
            
            strongSelf.delegate?.logInViewControllerDidAuthenticate(strongSelf, instanceURL: instanceURL, credential: credential)
        }
    }
    
    private func presentAlert(for error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel))
        
        present(alert, animated: true)
    }
    
}

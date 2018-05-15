//
//  LogInViewController.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/6/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

protocol LogInViewControllerDelegate: class {
    func logInViewControllerDidAuthenticate(_ controller: LogInViewController, instanceURL: URL, credential: OAuthCredential, authProvider: AuthProvider)
}

class LogInViewController: UIViewController {
    
    let sampleUsername = "sampleUser"
    let samplePassword = "samplePassword"
    let sampleInstance = "https://snowchat.service-now.com"
    
    private var authManager: OAuthManager?
    private var initialInstanceURL: URL?
    
    weak var delegate: LogInViewControllerDelegate?

    @IBOutlet private weak var instanceTextField: UITextField!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField! {
        didSet {
            passwordTextField.returnKeyType = .go
            passwordTextField.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)
        }
    }
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var openIDButton: UIButton!
    @IBOutlet private weak var logInButton: UIButton!
    
    private var instanceURL: URL? {
        guard let instanceText = instanceTextField.text else { return nil }
        return URL(serverInstanceString: instanceText)
    }
    
    // MARK: - Initialization
    
    convenience init(instanceURL: URL? = nil) {
        self.init()
        initialInstanceURL = instanceURL
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Log In", comment: "")
        
        instanceTextField.text = initialInstanceURL?.absoluteString
    }
    
    // MARK: - UI Updates
    
    private func updateUI(isLoading: Bool) {
        logInButton.isEnabled = !isLoading
        openIDButton.isEnabled = !isLoading
        usernameTextField.isEnabled = !isLoading
        passwordTextField.isEnabled = !isLoading
        instanceTextField.isEnabled = !isLoading
        isLoading ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
    }
    
    // MARK: - Actions
    
    @IBAction private func logInButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text,
            let password = passwordTextField.text,
            let instanceURL = self.instanceURL else { return }
        
        logIn(username: username, password: password,  instanceURL: instanceURL, authProvider: .local)
    }

    @objc private func enterPressed() {
        guard let username = usernameTextField.text,
            let password = passwordTextField.text,
            let instanceURL = self.instanceURL else { return }
        
        logIn(username: username, password: password,  instanceURL: instanceURL, authProvider: .local)
    }
    
    @IBAction private func useOpenIDButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text,
            let password = passwordTextField.text,
            let instanceURL = self.instanceURL else { return }
        
        logIn(username: username, password: password, instanceURL: instanceURL, authProvider: .openID)
    }
    
    @IBAction func sampleLoginTapped(_ sender: Any) {
        guard let sampleInstanceURL = URL(string: sampleInstance) else { return }
        logIn(username: sampleUsername, password: samplePassword,  instanceURL: sampleInstanceURL, authProvider: .local)
    }

    // MARK: - Log In
    
    private func logIn(username: String, password: String, instanceURL: URL, authProvider: AuthProvider) {
        view.endEditing(true)
        
        updateUI(isLoading: true)
        
        let authManager = OAuthManager(authProvider: authProvider, instanceURL: instanceURL)
        self.authManager = authManager
        
        authManager.authenticate(username: username, password: password) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.updateUI(isLoading: false)
            
            guard case let .success(credential) = result else {
                // swiftlint:disable:next force_unwrapping
                self?.presentAlert(for: result.error!)
                return
            }
            
            strongSelf.delegate?.logInViewControllerDidAuthenticate(strongSelf, instanceURL: instanceURL, credential: credential, authProvider: authProvider)
        }
    }
    
    private func presentAlert(for error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel))
        
        present(alert, animated: true)
    }
    
}

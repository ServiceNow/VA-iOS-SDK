//
//  InstanceSettingsViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 1/4/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class InstanceSettingsViewController: UIViewController {

    @IBOutlet weak var instanceTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Instance Settings"
        
        setupButtons()
        updateFields()
    }
    
    // MARK: - Setup
    
    private func setupButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped(_:)))
    }
    
    private func updateFields() {
        instanceTextField.text = DebugSettings.shared.instanceURL.absoluteString
        usernameTextField.text = DebugSettings.shared.username
        passwordTextField.text = DebugSettings.shared.password
    }
    
    // MARK: - Actions
    
    @objc private func saveButtonTapped(_ sender: Any) {
        saveValues()
        updateFields()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func cancelButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Data
    
    private func saveValues() {
        if let instanceString = instanceTextField.text, let url = ServerInstance.instanceURL(fromUserInput: instanceString) {
            DebugSettings.shared.instanceURL = url
        }
        
        if let username = usernameTextField.text {
            DebugSettings.shared.username = username
        }
        
        if let password = passwordTextField.text {
            DebugSettings.shared.password = password
        }
    }
    
}

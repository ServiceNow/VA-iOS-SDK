//
//  DebugViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 11/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

public class DebugViewController: UITableViewController, ChatServiceDelegate {
    
    @IBOutlet private weak var uiControlsCell: UITableViewCell!
    @IBOutlet private weak var chatWindowCell: UITableViewCell!
    @IBOutlet private weak var instanceSettingsCell: UITableViewCell!
    
    var instance = ServerInstance(instanceURL: DebugSettings.shared.instanceURL)
    private var chatService: ChatService?
    private var lastCredentials: ChatUserCredentials?
    
    // MARK: - Initialization
    
    public class func fromStoryboard() -> DebugViewController {
        let storyboard = UIStoryboard(name: "Debug", bundle: Bundle(for: self))
        let controller = storyboard.instantiateInitialViewController() as! DebugViewController
        return controller
    }
    
    // MARK: - View Life Cycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Debug 🐞"

        chatWindowCell?.enable(false)

        chatService = ChatService(instance: instance, delegate: self)
        chatService?.establishUserSession({ error in
            if let error = error {
                self.presentError(error)
                return
            } else {
                self.chatWindowCell?.enable(true)
            }
        })
    }
    
    // MARK: - UITableViewDelegate
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        switch cell {
        case uiControlsCell:
            pushControlsViewController()
        case chatWindowCell:
            pushChatController()
        case instanceSettingsCell:
            pushInstanceSettingsViewController()
        default:
            break // noop
        }
    }
    
    // MARK: - ChatServiceDelegate
    
    public func userCredentials(for chatService: ChatService) -> ChatUserCredentials? {
        guard let instanceChatService = self.chatService, instanceChatService == chatService else { return nil }
        
        let credentials = ChatUserCredentials(username: DebugSettings.shared.username,
                                              password: DebugSettings.shared.password,
                                              vendorId: "c2f0b8f187033200246ddd4c97cb0bb9")
        lastCredentials = credentials
        return credentials
    }
    
    // MARK: - Navigation
    
    private func pushControlsViewController() {
        let controller = ControlsViewController(nibName: nil, bundle: Bundle(for: ControlsViewController.self))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushInstanceSettingsViewController() {
        let controller = InstanceSettingsViewController(nibName: nil, bundle: Bundle(for: InstanceSettingsViewController.self))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushChatController() {
        Logger.logger(for: "AMBClient").logLevel = .Error
        Logger.logger(for: "Chatterbox").logLevel = .Debug
        
        guard let chatService = chatService else { return }
        
        // if instance info has changed, or we have not yet initialize chatService, then establish
        // the user session and show the view controller when done
        // otherwise just present the view controller and save a lot of time
        
        if !chatService.initialized || updateSettingsIfChanged() {
            let activity = activityIndicator()
            activity.startAnimating()
            
            chatService.establishUserSession({ error in
                activity.stopAnimating()
                
                if let error = error {
                    self.presentError(error)
                    return
                }

                self.presentChatViewController()
            })
        } else {
            presentChatViewController()
        }
    }
    
    private func activityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.color = UIColor.red
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        return activityIndicator
    }
    
    private func updateSettingsIfChanged() -> Bool {
        if instance.instanceURL != DebugSettings.shared.instanceURL {
            instance = ServerInstance(instanceURL: DebugSettings.shared.instanceURL)
            chatService = ChatService(instance: instance, delegate: self)
            return true
        }
        // see if user credentials changed
        if DebugSettings.shared.username != lastCredentials?.username ||
           DebugSettings.shared.password != lastCredentials?.password {
            return true
        }
        return false
    }
    
    fileprivate func presentChatViewController() {
        if let controller = chatService?.chatViewController() {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    private func presentError(_ error: ChatServiceError) {
        var message: String = error.localizedDescription
        switch error {
        case .noSession(let chatError):
            if  let apiError = chatError as? APIManager.APIManagerError {
                switch apiError {
                case .loginError(message: let errorMessage):
                    message = errorMessage
                }
            }
        case .sessionInitializing(let errorMessage):
            message = errorMessage
        default:
            break
        }
        let alert = UIAlertController()
        alert.title = "\(message)"
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
            self.tableView.reloadData()
        }))
        present(alert, animated: true) {}
    }
}

extension UITableViewCell {
    func enable(_ enable: Bool) {
        self.isUserInteractionEnabled = enable
        for view in contentView.subviews {
            view.isUserInteractionEnabled = enable
            view.alpha = enable ? 1 : 0.5
        }
    }
}

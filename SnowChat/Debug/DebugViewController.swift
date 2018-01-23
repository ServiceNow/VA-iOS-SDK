//
//  DebugViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 11/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

public class DebugViewController: UITableViewController, ChatServiceDelegate {
    
    @IBOutlet private weak var ambTestCell: UITableViewCell!
    @IBOutlet private weak var uiControlsCell: UITableViewCell!
    @IBOutlet private weak var chatWindowCell: UITableViewCell!
    @IBOutlet private weak var instanceSettingsCell: UITableViewCell!
    
    private var chatService: ChatService?
    
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
    }
    
    // MARK: - UITableViewDelegate
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        switch cell {
        case ambTestCell:
            pushAMBViewController()
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
    
    func userCredentials() -> ChatUserCredentials {
        return ChatUserCredentials(username: DebugSettings.shared.username,
                                   password: DebugSettings.shared.password,
                                   vendorId: "c2f0b8f187033200246ddd4c97cb0bb9")
    }
    
    // MARK: - Navigation
    
    private func pushChatController() {
        let instance = ServerInstance(instanceURL: DebugSettings.shared.instanceURL)
        chatService = ChatService(instance: instance, delegate: self)
        
        Logger.logger(for: "AMBClient").logLevel = .Error
        Logger.logger(for: "Chatterbox").logLevel = .Debug
        
        if let controller = chatService?.chatViewController() {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    private func pushAMBViewController() {
        let controller = AMBTestPanelViewController(nibName: nil, bundle: Bundle(for: AMBTestPanelViewController.self))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushControlsViewController() {
        let controller = ControlsViewController(nibName: nil, bundle: Bundle(for: ControlsViewController.self))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushInstanceSettingsViewController() {
        let controller = InstanceSettingsViewController(nibName: nil, bundle: Bundle(for: InstanceSettingsViewController.self))
        navigationController?.pushViewController(controller, animated: true)
    }
    
}

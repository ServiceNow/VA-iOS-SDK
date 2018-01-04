//
//  DebugViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 11/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

public class DebugViewController: UITableViewController, ChatServiceAppDelegate {
    
    @IBOutlet private weak var ambTestCell: UITableViewCell!
    @IBOutlet private weak var uiControlsCell: UITableViewCell!
    @IBOutlet private weak var chatWindowCell: UITableViewCell!
    
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
        default:
            break // noop
        }
    }
    
    // MARK: ChatServiceAppDelegate methods
    
    func userCredentials() -> ChatUserCredentials {
        return ChatUserCredentials(userName: "admin",
                                   userPassword: "snow2004",
                                   vendorId: "c2f0b8f187033200246ddd4c97cb0bb9",
                                   consumerId: CBData.uuidString(),
                                   consumerAccountId: CBData.uuidString())
    }
    
    // MARK: - Navigation
    
    private func pushChatController() {
        chatService = ChatService(delegate: self)
        if let controller = chatService?.chatViewController() {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    private func pushAMBViewController() {
        let controller = AMBTestPanelViewController(nibName: "AMBTestPanelViewController", bundle: Bundle(for: type(of: self)))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushControlsViewController() {
        let controller = ControlsViewController(nibName: "ControlsViewController", bundle: Bundle(for: ControlsViewController.self))
        navigationController?.pushViewController(controller, animated: true)
    }
    
}

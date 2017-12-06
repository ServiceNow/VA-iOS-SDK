//
//  DebugViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 11/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

public class DebugViewController: UITableViewController {
    
    @IBOutlet private weak var ambTestCell: UITableViewCell!
    @IBOutlet private weak var uiControlsCell: UITableViewCell!
    
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
        default:
            break // noop
        }
    }
    
    // MARK: - Navigation
    
    private func pushAMBViewController() {
        let controller = AMBTestPanelViewController(nibName: "AMBTestPanelViewController", bundle: Bundle(for: type(of: self)))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushControlsViewController() {
        let controller = ControlsViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
}

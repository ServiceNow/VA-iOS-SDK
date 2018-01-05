//
//  FakeChatViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class FakeChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    
    var observer: NSKeyValueObservation?
    
    var messageViewControllers = [MessageViewController]()
    
    var controls: [ControlProtocol]? {
        didSet {
            
            // Each cell will have its own view controller to handle each message
            // It will need to be definitely improved. I just added simple solution
            // More on it: http://khanlou.com/2015/04/view-controllers-in-cells/
            messageViewControllers.forEach({
                $0.removeUIControl()
                $0.removeFromParentViewController()
            })
            messageViewControllers.removeAll()
            
            guard let controls = controls else { return }
            for _ in controls {
                let controller = MessageViewController(nibName: "MessageViewController", bundle: Bundle(for: type(of: self)))
                controller.willMove(toParentViewController: self)
                addChildViewController(controller)
                messageViewControllers.append(controller)
            }
            
            tableView.reloadData()
            
            // Due to silly self-sizing problems with UITableViewCell I am forcing table to draw itself after data are reloaded
            // This will trigger UIControl to be placed in the cell and update its height
            // Then we need to call beginUpdates() endUpdates() on cell to refresh cell height
            tableView.setNeedsLayout()
            tableView.layoutIfNeeded()
            
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = view.bounds
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(FakeChatViewCell.self, forCellReuseIdentifier: "ChatCell")
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controls?.count ?? 0
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! FakeChatViewCell
        cell.selectionStyle = .none
        
        guard let control = controls?[indexPath.row] else {
            return cell
        }
        
        let messageViewController = messageViewControllers[indexPath.row]
        let messageView: UIView = messageViewController.view
        cell.messageView = messageView
        messageViewController.addUIControl(control, at: .left)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let messageViewController = messageViewControllers[indexPath.row]
        messageViewController.didMove(toParentViewController: self)
    }
}

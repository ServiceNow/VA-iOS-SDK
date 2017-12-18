//
//  FakeChatViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// Add view controllers caching in actual app: http://khanlou.com/2015/04/view-controllers-in-cells/

import UIKit

class FakeChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    
    var observer: NSKeyValueObservation?
    
    var messageViewControllers = [MessageViewController]()
    
    var controls: [ControlProtocol]? {
        didSet {
            
            messageViewControllers.forEach({
                $0.removeUIControl()
                $0.removeFromParentViewController()
            })
            messageViewControllers.removeAll()
            tableView.reloadData()
            
            guard let controls = controls else { return }
            for control in controls {
                let controller = MessageViewController(nibName: "MessageViewController", bundle: Bundle(for: type(of: self)))
                controller.willMove(toParentViewController: self)
                addChildViewController(controller)
                messageViewControllers.append(controller)
                
                if let scroll = (control.viewController.view as? FullSizeScrollViewContainerView)?.scrollView {
                    observer = scroll.observe(\UIScrollView.contentSize) { [weak self] (scrollView, change) in
                        self?.tableView.reloadData()
                    }
                }
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
        messageViewController.addUIControl(control)
        cell.messageView = messageView
        return cell
    }
}

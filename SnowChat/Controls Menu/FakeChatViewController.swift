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
    
    var controls: [ControlProtocol]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = view.bounds
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controls?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        
        let messageViewController = MessageViewController()
        messageViewController.willMove(toParentViewController: self)
        addChildViewController(messageViewController)
//        cell.contentView.layer.borderColor = UIColor.blue.cgColor
//        cell.contentView.layer.borderWidth = 1
        
        let messageView: UIView = messageViewController.view
        messageView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(messageView)
        NSLayoutConstraint.activate([messageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                                     messageView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                                     messageView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                                     messageView.heightAnchor.constraint(equalTo: cell.contentView.heightAnchor)])
        messageViewController.didMove(toParentViewController: self)
        
        if let control = controls?[indexPath.row] {
            messageViewController.addUIControl(control)
        }
        
        return cell
    }
}

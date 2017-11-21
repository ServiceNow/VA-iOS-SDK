//
//  ControlsViewController.swift
//  SnowKangaroo
//
//  Created by Michael Borowiec on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class ControlsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var controlContainerView: UIView!
    private var controls = ["Boolean Picker"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = controls[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bubbleViewController = MockBubbleViewController()
        bubbleViewController.willMove(toParentViewController: self)
        addChildViewController(bubbleViewController)
        bubbleViewController.didMove(toParentViewController: self)
        
        guard let bubbleView = bubbleViewController.view else {
            return
        }
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubbleView)
        NSLayoutConstraint.activate([bubbleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     bubbleView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                     bubbleView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
                                     bubbleView.heightAnchor.constraint(equalToConstant: 150)])
    }
}

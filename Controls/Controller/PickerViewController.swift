//
//  PickerViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView: UITableView?
    
    var model: PickerControlViewModel? {
        didSet {
            tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).cgColor

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     tableView.topAnchor.constraint(equalTo: view.topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        
        // TODO: need to adjust based on the number of items etc
        tableView.isScrollEnabled = false
        
        self.tableView = tableView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        
        if let displayValue = model?.displayValues?[indexPath.row] {
            cell.textLabel?.text = displayValue
            cell.textLabel?.textAlignment = .center
        }

        return cell
    }
}

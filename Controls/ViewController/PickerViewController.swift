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
        let roundedView = RoundedView(frame: CGRect.zero)
        roundedView.corners = [.bottomLeft, .bottomRight]
        roundedView.cornerRadius = 10
        
        roundedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedView)
        NSLayoutConstraint.activate([roundedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     roundedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     roundedView.topAnchor.constraint(equalTo: view.topAnchor),
                                     roundedView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        tableView.translatesAutoresizingMaskIntoConstraints = false
        roundedView.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.leadingAnchor.constraint(equalTo: roundedView.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: roundedView.trailingAnchor),
                                     tableView.topAnchor.constraint(equalTo: roundedView.topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: roundedView.bottomAnchor)])

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
        cell.contentView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
        cell.selectionStyle = .none
        
        if let displayValue = model?.displayValues?[indexPath.row] {
            cell.textLabel?.text = displayValue
            cell.textLabel?.textAlignment = .center
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedItem = model?.items?[indexPath.row] {
            selectedItem.isSelected = true
        }
    }
    
    
}

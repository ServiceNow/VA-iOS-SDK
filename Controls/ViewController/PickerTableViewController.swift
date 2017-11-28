//
//  PickerTableViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class PickerTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var fullSizeContainer: FullSizeScrollViewContainerView?
    
    var tableView: UITableView?
    
    var isMultiselect: Bool = false
    
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
        let fullSizeContainer = FullSizeScrollViewContainerView(frame: CGRect.zero)
        fullSizeContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fullSizeContainer)
        NSLayoutConstraint.activate([fullSizeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     fullSizeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     fullSizeContainer.topAnchor.constraint(equalTo: view.topAnchor),
                                     fullSizeContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainer.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.leadingAnchor.constraint(equalTo: fullSizeContainer.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: fullSizeContainer.trailingAnchor),
                                     tableView.topAnchor.constraint(equalTo: fullSizeContainer.topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: fullSizeContainer.bottomAnchor)])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        
        tableView.sectionHeaderHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // TODO: need to adjust based on the number of items etc
        tableView.isScrollEnabled = false
        self.tableView = tableView
        
        fullSizeContainer.scrollView = tableView
        self.fullSizeContainer = fullSizeContainer
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let titleLabel = UILabel()
        titleLabel.text = model?.title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([titleLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 10),
                                     titleLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: 10),
                                     titleLabel.heightAnchor.constraint(equalTo: headerView.heightAnchor, multiplier: 0.8),
                                     titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 10)])
        return headerView
    }
}

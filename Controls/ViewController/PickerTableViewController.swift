//
//  PickerTableViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class PickerTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let headerTextColor = UIColor(red: 73 / 255, green: 96 / 255, blue: 116 / 255, alpha: 1)
    
    var fullSizeContainer: FullSizeScrollViewContainerView?
    
    var tableView: UITableView?
    
    var model: PickerControlViewModel {
        didSet {
            tableView?.reloadData()
        }
    }
    
    // MARK: - Initialization
    
    init(model: PickerControlViewModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
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
        
        let bundle = Bundle(for: PickerTableViewController.self)
        if model.isMultiselect {
            tableView.register(SelectableViewCell.self, forCellReuseIdentifier: SelectableViewCell.cellIdentifier)
        } else {
            tableView.register(UINib(nibName: "PickerTableViewCell", bundle: bundle), forCellReuseIdentifier: PickerTableViewCell.cellIdentifier)
        }
        
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
        
        tableView.sectionHeaderHeight = 30
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // TODO: need to adjust based on the number of items etc
        tableView.isScrollEnabled = false
        self.tableView = tableView
        
        fullSizeContainer.scrollView = tableView
        fullSizeContainer.maxHeight = 150
        self.fullSizeContainer = fullSizeContainer
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = model.isMultiselect ? SelectableViewCell.cellIdentifier : PickerTableViewCell.cellIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.contentView.backgroundColor = UIColor.white
        cell.selectionStyle = .none
        
        guard let configurableCell: ConfigurablePickerCell = cell as? ConfigurablePickerCell else {
            return cell
        }
        
        if let itemModel = model.items?[indexPath.row] {
            configurableCell.configure(withModel: itemModel)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedItem = model.items?[indexPath.row] {
            selectedItem.isSelected = true
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let titleLabel = UILabel()
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.text = model.title
        titleLabel.textColor = headerTextColor
        headerView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([titleLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 10),
                                     titleLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -10),
                                     titleLabel.heightAnchor.constraint(equalTo: headerView.heightAnchor, multiplier: 0.8),
                                     titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0)])
        return headerView
    }
}

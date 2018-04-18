//
//  TableFooterView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 4/17/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

class TableFooterView: UIView {
    
    private let emptyView = UIView()
    private weak var tableView: UITableView?
    private var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    var isLoading = false {
        didSet {
            if isLoading == true {
                tableView?.tableFooterView = self
            } else {
                tableView?.tableFooterView = emptyView
            }
        }
    }
    
    static func footerView(for tableView: UITableView) -> TableFooterView {
        let tableFooterView = TableFooterView(tableView: tableView)
        tableView.tableFooterView = tableFooterView.emptyView
        return tableFooterView
    }
    
    init(tableView: UITableView) {
        super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 50))
        self.tableView = tableView
        setupActivityIndicator()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        activityIndicator.startAnimating()
    }
}

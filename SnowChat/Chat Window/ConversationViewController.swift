//
//  ConversationViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import SlackTextViewController

class ConversationViewController: SLKTextViewController {
    
    private let dataController: ChatDataController
    
    override var tableView: UITableView {
        // swiftlint:disable:next force_unwrapping
        return super.tableView!
    }
    
    // MARK: - Initialization
    
    init(chatterbox: Chatterbox) {
        dataController = ChatDataController(chatterbox: chatterbox)
        
        // swiftlint:disable:next force_unwrapping
        super.init(tableViewStyle: .plain)!
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    // MARK: - View Setup
    
    private func setupTableView() {
        tableView.separatorStyle = .none
    }
    
}

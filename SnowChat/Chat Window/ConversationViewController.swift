//
//  ConversationViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import SlackTextViewController

class ConversationViewController: SLKTextViewController, ViewDataChangeListener {
    
    private let dataController: ChatDataController
    
    override var tableView: UITableView {
        // swiftlint:disable:next force_unwrapping
        return super.tableView!
    }
    
    // MARK: - Initialization
    
    init?(chatterbox: Chatterbox) {
        dataController = ChatDataController(chatterbox: chatterbox)

        super.init(tableViewStyle: .plain)
        
        dataController.changeListener = self
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }

    // MARK: - View Setup
    
    private func setupTableView() {
        tableView.separatorStyle = .none
    }

    func didChange(_ model: ControlViewModel, atIndex index: Int) {
        tableView.reloadData()
        
        // TODO: optimize to update changed rows if possible...
    }
}

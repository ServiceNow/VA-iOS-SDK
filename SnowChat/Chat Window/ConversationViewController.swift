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
    
    init?(chatterbox: Chatterbox) {
        dataController = ChatDataController(chatterbox: chatterbox)

        super.init(tableViewStyle: .plain)
        
        chatterbox.chatDataListener = self
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

extension ConversationViewController: ChatDataListener {
    
    func chatterbox(_: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String) {
        Logger.default.logDebug("BooleanControl: \(message)")
    }
    
    func chatterbox(_: Chatterbox, didReceiveInputData message: InputControlMessage, forChat chatId: String) {
        Logger.default.logDebug("InputControl: \(message)")
    }
    
    func chatterbox(_: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String) {
        Logger.default.logDebug("PickerControl: \(message)")
    }
    
    func chatterbox(_: Chatterbox, didReceiveTextData message: OutputTextMessage, forChat chatId: String) {
        Logger.default.logDebug("TextControl: \(message)")
    }
}

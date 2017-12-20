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
    
    private enum InputState {
        case inSystemTopicSelection     // user can select topic, talk to tagent, or quit
        case inTopicSelection           // user is searching topics
        case inConversation             // user is in an active conversation
    }
    
    private var inputState = InputState.inTopicSelection
    private let dataController: ChatDataController
    private let chatterbox: Chatterbox
    
    private var autocompleteHandler: AutoCompleteHandler?
    
    override var tableView: UITableView {
        // swiftlint:disable:next force_unwrapping
        return super.tableView!
    }
    
    // MARK: - Initialization
    
    init(chatterbox: Chatterbox) {
        self.chatterbox = chatterbox
        self.dataController = ChatDataController(chatterbox: chatterbox)

        // NOTE: this failable initializer cannot really fail, so keeping it clean and forcing
        // swiftlint:disable:next force_unwrapping
        super.init(tableViewStyle: .plain)!
        
        self.dataController.changeListener = self
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
        
        // NOTE: making section header height very tiny as 0 make it default size in iOS11
        //  see https://stackoverflow.com/questions/46594585/how-can-i-hide-section-headers-in-ios-11
        tableView.sectionHeaderHeight = CGFloat(0.01)
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        
        setupInputForState()
    }

    private func setupInputForState() {
        switch inputState {
        case .inTopicSelection:
            setupForTopicSelection()
        case .inSystemTopicSelection:
            setupForSystemTopicSelection()
        case .inConversation:
            setupForConversation()
        }
    }
    
    private func setupForSystemTopicSelection() {
        // TODO: install autocomplete handler for system topic choices
    }
    
    private func setupForTopicSelection() {
        self.autocompleteHandler = TopicSelectionHandler(withController: self, chatterbox: chatterbox)
    }
    
    private func setupForConversation() {
        registerPrefixes(forAutoCompletion: [])
        self.autocompleteHandler = nil
        
        rightButton.isHidden = false
        rightButton.setTitle(NSLocalizedString("Send", comment: "Right button label in conversation mode"), for: UIControlState())
        textView.placeholder = NSLocalizedString("...", comment: "Placeholder text for input field when user is in a conversation")
    }
    
    // MARK: ViewDataChangeListener
    
    func chatDataController(_ dataController: ChatDataController, didChangeModel model: ControlViewModel, atIndex index: Int) {
        tableView.reloadData()
        
        // TODO: optimize to update changed rows if possible...
    }
}

extension ConversationViewController {
    
    // MARK: SLKTextViewController overrides
    
    override func didChangeAutoCompletionPrefix(_ prefix: String, andWord word: String) {
        super.didChangeAutoCompletionPrefix(prefix, andWord: word)
        
        autocompleteHandler?.didChangeAutoCompletionText(withPrefix: prefix, andWord: word)
    }
    
    override func textDidUpdate(_ animated: Bool) {
        super.textDidUpdate(animated)
        
        switch inputState {
        case .inTopicSelection:
            let searchText: String = textView.text ?? ""
            if let handler = autocompleteHandler {
                handler.textDidChange(searchText)
            }
        default:
            Logger.default.logDebug("Right button or enter pressed: state=\(inputState)")
        }
    }
    
    override func didPressRightButton(_ sender: Any?) {
        didCommitTextEditing(sender)
    }
    
    override func didCommitTextEditing(_ sender: Any) {
        super.didCommitTextEditing(sender)
        
        switch inputState {
        case .inTopicSelection:
            let searchText: String = textView.text ?? ""
            if let handler = autocompleteHandler {
                handler.didCommitEditing(searchText)
            }
        default:
            Logger.default.logDebug("Right button or enter pressed: state=\(inputState)")
        }
        
    }
    
    override func heightForAutoCompletionView() -> CGFloat {
       return autocompleteHandler?.heightForAutoCompletionView() ?? 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == autoCompletionView, let handler = autocompleteHandler {
            return handler.numberOfSections()
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if tableView == autoCompletionView, let handler = autocompleteHandler {
            count = handler.numberOfRowsInSection(section)
        }
        return count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == autoCompletionView {
            autocompleteHandler?.didSelectRowAt(indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == autoCompletionView, let handler = autocompleteHandler {
            return handler.cellForRowAt(indexPath)
        } else {
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == autoCompletionView, let handler = autocompleteHandler {
            return handler.viewForHeaderInSection(section)
        } else {
            return nil
        }
    }
}

extension ConversationViewController: ChatEventListener {
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topic: StartedUserTopicMessage, forChat chatId: String) {
        if self.chatterbox.id == chatterbox.id {
            
            inputState = .inConversation
            setupInputForState()
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topic: TopicFinishedMessage, forChat chatId: String) {
        if self.chatterbox.id == chatterbox.id {
            
            inputState = .inTopicSelection
            setupInputForState()
        }
    }
}

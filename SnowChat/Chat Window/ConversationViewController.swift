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
    private var autocompleteHandler: AutoCompleteHandler?

    private let dataController: ChatDataController
    private let chatterbox: Chatterbox

    private var messageViewControllerCache = ChatMessageViewControllerCache()
    private var uiControlCache = ControlCache()
    
    override var tableView: UITableView {
        // swiftlint:disable:next force_unwrapping
        return super.tableView!
    }
    
    private var presentedWelcomeMessage = false
    
    // MARK: - Initialization
    
    init(chatterbox: Chatterbox) {
        self.chatterbox = chatterbox
        self.dataController = ChatDataController(chatterbox: chatterbox)

        // NOTE: this failable initializer cannot really fail, so keeping it clean and forcing
        // swiftlint:disable:next force_unwrapping
        super.init(tableViewStyle: .plain)!        

        self.dataController.setChangeListener(self)
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
        
        // NOTE: making section header height very tiny as 0 make it default size in iOS11
        //  see https://stackoverflow.com/questions/46594585/how-can-i-hide-section-headers-in-ios-11
        tableView.sectionHeaderHeight = CGFloat(0.01)
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(ConversationViewCell.self, forCellReuseIdentifier: ConversationViewCell.cellIdentifier)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // FIXME: Still need to add case for keyboard shown etc. This covers only a very basic use case.
        var insets = tableView.contentInset
        insets.top = 30
        tableView.contentInset = insets
    }
    
    private func setupForSystemTopicSelection() {
        // TODO: install autocomplete handler for system topic choices
    }
    
    private func presentWelcomeIfNeeded() {
        guard presentedWelcomeMessage == false else { return }
        
        dataController.presentWelcomeMessage()
        presentedWelcomeMessage = true
    }
    
    private func setupForTopicSelection() {
        self.autocompleteHandler = TopicSelectionHandler(withController: self, chatterbox: chatterbox)
        
        setTextInputbarHidden(false, animated: true)
        
        textView.text = ""
        textView.placeholder = NSLocalizedString("Type your question here...", comment: "Placeholder text for input field when user is selecting a topic")

        presentWelcomeIfNeeded()
    }
    
    private func setupForConversation() {
        registerPrefixes(forAutoCompletion: [])
        self.autocompleteHandler = nil
        
        rightButton.isHidden = false
        rightButton.setTitle(NSLocalizedString("Send", comment: "Right button label in conversation mode"), for: UIControlState())
        
        textView.text = ""
        textView.placeholder = NSLocalizedString("...", comment: "Placeholder text for input field when user is in a conversation")
    }
    
    // MARK: - ViewDataChangeListener
    
    func chatDataController(_ dataController: ChatDataController, didChangeModel model: ChatMessageModel, atIndex index: Int) {
        manageInputControl()
        tableView.reloadData()
    }
    
    func manageInputControl() {
        switch inputState {
        case  .inConversation:
            // during conversation we hide the input when displaying any control other than text as the last one
            let count = dataController.controlCount()
            if count > 0, let lastControl = dataController.controlForIndex(0) {
                textView.text = ""
                isTextInputbarHidden = lastControl.controlModel.type != .text
                if !isTextInputbarHidden {
                    textView.becomeFirstResponder()
                }
            }
        case .inTopicSelection:
            if !textView.isFocused {
                textView.becomeFirstResponder()
            }
        default:
            Logger.default.logDebug("unhandled inputState in manageInputControl: \(inputState)")
        }
    }
}

extension ConversationViewController {
    
    // MARK: - SLKTextViewController overrides
    
    override func didChangeAutoCompletionPrefix(_ prefix: String, andWord word: String) {
        super.didChangeAutoCompletionPrefix(prefix, andWord: word)
        
        autocompleteHandler?.didChangeAutoCompletionText(withPrefix: prefix, andWord: word)
    }
    
    override func textDidUpdate(_ animated: Bool) {
        super.textDidUpdate(animated)
        
        switch inputState {
        case .inTopicSelection:
            let searchText: String = textView.text ?? ""
            autocompleteHandler?.textDidChange(searchText)
        default:
            Logger.default.logDebug("Right button or enter pressed: state=\(inputState)")
        }
    }
    
    override func didPressRightButton(_ sender: Any?) {
        didCommitTextEditing(sender ?? self)
    }
    
    override func didCommitTextEditing(_ sender: Any) {
        super.didCommitTextEditing(sender)

        let inputText: String = textView.text ?? ""

        switch inputState {
        case .inTopicSelection:
            autocompleteHandler?.didCommitEditing(inputText)
        case .inConversation:
            processUserInput(inputText)
        default:
            Logger.default.logDebug("Right button or enter pressed: state=\(inputState)")
        }
    }
    
    func processUserInput(_ inputText: String) {
        // send the input as a control update
        let model = TextControlViewModel(id: CBData.uuidString(), value: inputText)
        dataController.updateControlData(model, isSkipped: false)
    }
    
    override func heightForAutoCompletionView() -> CGFloat {
       return autocompleteHandler?.heightForAutoCompletionView() ?? 0
    }
    
    override func maximumHeightForAutoCompletionView() -> CGFloat {
        // default is 140, but even on iPhone SE 200 fits fine with keyboard up
        return 200
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == autoCompletionView, let handler = autocompleteHandler {
            return handler.numberOfSections()
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        
        if tableView == autoCompletionView, let handler = autocompleteHandler {
            return handler.numberOfRowsInSection(section)
        }
        
        return dataController.controlCount()
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
            
           return conversationCellForRowAt(indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == autoCompletionView {
            return
        }

        messageViewControllerCache.removeViewController(at: indexPath)
        guard let chatMessageModel = dataController.controlForIndex(indexPath.row) else {
            fatalError("Something went wrong, ControlModel should exist")
        }
        
        uiControlCache.prepareControlForReuse(withModel: chatMessageModel.controlModel)
    }
    
    private func conversationCellForRowAt(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationViewCell.cellIdentifier, for: indexPath) as! ConversationViewCell
        configureConversationCell(cell, at: indexPath)
        return cell
    }
    
    private func configureConversationCell(_ cell: ConversationViewCell, at indexPath:IndexPath) {

        if let chatMessageModel = dataController.controlForIndex(indexPath.row) {
            let messageViewController = messageViewControllerCache.getViewController(for: indexPath, movedToParentViewController: self)
            cell.messageView = messageViewController.view
            let uiControl = uiControlCache.control(forModel: chatMessageModel.controlModel)
            messageViewController.addUIControl(uiControl, at: chatMessageModel.location)
            messageViewController.didMove(toParentViewController: self)
            messageViewController.uiControl?.delegate = self
        }

        cell.selectionStyle = .none
        UIView.performWithoutAnimation {
            cell.transform = tableView.transform
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
    
    // MARK: - ChatEventListener
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topic: StartedUserTopicMessage, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
                return
        }

        dataController.topicDidStart(topic)
        
        inputState = .inConversation
        setupInputForState()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topic: TopicFinishedMessage, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }

        dataController.topicDidFinish(topic)
        
        inputState = .inTopicSelection
        setupInputForState()
    }
}

extension ConversationViewController: ControlDelegate {
    
    // MARK: - ControlDelegate
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel) {
        // TODO: how to determine if it was skipped?
        dataController.updateControlData(model, isSkipped: false)
    }
}

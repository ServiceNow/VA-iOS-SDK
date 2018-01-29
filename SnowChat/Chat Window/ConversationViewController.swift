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
    
    private let bottomInset: CGFloat = 30
    
    private var inputState = InputState.inTopicSelection
    private var autocompleteHandler: AutoCompleteHandler?

    private let dataController: ChatDataController
    private let chatterbox: Chatterbox

    private var messageViewControllerCache = ChatMessageViewControllerCache()
    private var uiControlCache = ControlCache()
    
    private var canFetchOlderMessages = false
    private var timeLastHistoryFetch: Date = Date()
    
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
    
    // MARK: - ContentInset fix
    
    override func viewWillLayoutSubviews() {
        // not calling super to override slack's behavior
        adjustContentInset()
    }
    
    private func adjustContentInset() {
        var contentInset = tableView.contentInset
        
        if #available(iOS 11.0, *) {
            contentInset.bottom = tableView.safeAreaInsets.top
        } else {
            // Fallback on earlier versions
            contentInset.bottom = topLayoutGuide.length
        }
        
        // we are inverted so top is really a bottom
        contentInset.top = bottomInset
        
        tableView.contentInset = contentInset
        tableView.scrollIndicatorInsets = contentInset
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
    
    private func setupForSystemTopicSelection() {
        // TODO: install autocomplete handler for system topic choices
    }
    
    private func setupForTopicSelection() {
        self.autocompleteHandler = TopicSelectionHandler(withController: self, chatterbox: chatterbox)
        
        setTextInputbarHidden(false, animated: true)
        
        textView.text = ""
        textView.placeholder = NSLocalizedString("Type your question here...", comment: "Placeholder text for input field when user is selecting a topic")
    }
    
    private func setupForConversation() {
        registerPrefixes(forAutoCompletion: [])
        self.autocompleteHandler = nil
        
        rightButton.isHidden = false
        rightButton.setTitle(NSLocalizedString("Send", comment: "Right button label in conversation mode"), for: UIControlState())
        
        textView.text = ""
        textView.placeholder = ""
        
        setTextInputbarHidden(true, animated: true)
    }
    
    // MARK: - ViewDataChangeListener
    
    private func updateModel(_ model: ChatMessageModel, atIndex index: Int) {
        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ConversationViewCell {
            addUIControl(forModel: model, inCell: cell)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })
        
//        self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    func controller(_ dataController: ChatDataController, didChangeModel changes: [ModelChangeType]) {
        manageInputControl()
        
        func modelUpdates() {
            changes.forEach({ [weak self] change in
                switch change {
                case .insert(let index, _):
                    self?.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .top)
                case .delete(let index):
                    self?.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .none)
                case .update(let index, _, let model):
                    updateModel(model, atIndex: index)
                }
            })
        }
        
        // Begin/End Updates will be depracated in a future release so switching to performBatchUpdates
        if #available(iOS 11.0, *) {
            tableView.performBatchUpdates({
                modelUpdates()
            }, completion: nil)
        } else {
            tableView.beginUpdates()
            modelUpdates()
            tableView.endUpdates()
        }
    }
    
    func controllerDidLoadContent(_ dataController: ChatDataController) {
        updateTableView()
        canFetchOlderMessages = true
    }
    
    private func updateTableView() {
        manageInputControl()
        tableView.reloadData()
    }
    
    func manageInputControl() {
        switch inputState {
        case  .inConversation:
            // during conversation we hide the input bar unless the last control is an input (TextControl with forInput property set)
            let count = dataController.controlCount()
            if count > 0, let lastControl = dataController.controlForIndex(0) {
                textView.text = ""

                if lastControl.controlModel is TextControlViewModel && lastControl.requiresInput {
                    isTextInputbarHidden = false
                    textView.becomeFirstResponder()
                } else {
                    isTextInputbarHidden = true
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        guard scrollView == tableView else { return }
        
        let scrollOffsetToFetch: CGFloat = 100
        if scrollView.contentOffset.y + tableView.bounds.height > (tableView.contentSize.height + scrollOffsetToFetch) {
            fetchOlderMessagesIfPossible()
        }
    }
    
    func fetchOlderMessagesIfPossible() {
        if canFetchOlderMessages,
            Date().timeIntervalSince(timeLastHistoryFetch) > 5.0 {
            
            canFetchOlderMessages = false

            dataController.fetchOlderMessages { [weak self] count in
                guard let strongSelf = self else { return }
                
                if count > 0 {
                    // TODO: need to provide indices for the updated rows...
                    strongSelf.tableView.reloadData()
                }
                strongSelf.canFetchOlderMessages = true
                strongSelf.timeLastHistoryFetch = Date()
            }
        }
    }
    
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
        case .inConversation:
            // TODO: validate the text against the input type when we have such a notion...
            Logger.default.logDebug("Text updated: \(textView.text)")
        default:
            Logger.default.logDebug("Text updated: state=\(inputState)")
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
    
    private func conversationCellForRowAt(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationViewCell.cellIdentifier, for: indexPath) as! ConversationViewCell
        configureConversationCell(cell, at: indexPath)
        return cell
    }
    
    private func configureConversationCell(_ cell: ConversationViewCell, at indexPath:IndexPath) {
        if let chatMessageModel = dataController.controlForIndex(indexPath.row) {
            let messageViewController = messageViewControllerCache.cachedViewController(movedToParentViewController: self)
            cell.messageViewController = messageViewController
            addUIControl(forModel: chatMessageModel, inCell: cell)
            messageViewController.didMove(toParentViewController: self)
        }

        cell.selectionStyle = .none
        cell.transform = tableView.transform
    }
    
    private func addUIControl(forModel model: ChatMessageModel, inCell cell: ConversationViewCell) {
        let uiControl = uiControlCache.control(forModel: model.controlModel)
        cell.messageViewController?.addUIControl(uiControl, at: model.location)
        uiControl.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == autoCompletionView, let handler = autocompleteHandler {
            return handler.viewForHeaderInSection(section)
        } else {
            return nil
        }
    }
    
    // MARK: - ChatMessageViewController reuse
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == autoCompletionView {
            return
        }
        
        prepareChatMessageViewControllerForReuse(for: cell)
    }
    
    private func prepareChatMessageViewControllerForReuse(for cell: UITableViewCell) {
        guard let conversationCell = cell as? ConversationViewCell else {
            fatalError("Wrong cell's class")
        }
        
        guard let messageViewController = conversationCell.messageViewController else {
            return
        }
        
        if let controlModel = messageViewController.uiControl?.model {
            uiControlCache.cacheControl(forModel: controlModel)
        }
        
        messageViewControllerCache.cacheViewController(messageViewController)
        conversationCell.messageViewController = nil
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

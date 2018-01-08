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

    // Each cell will have its own view controller to handle each message
    // Caching of VC based on: http://khanlou.com/2015/04/view-controllers-in-cells/
    private var messageViewControllersByIndexPath = [IndexPath : MessageViewController]()
    private var messageViewControllersToReuse = Set<MessageViewController>()
    
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

    // MARK: - View Setup
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        
        // NOTE: making section header height very tiny as 0 make it default size in iOS11
        //  see https://stackoverflow.com/questions/46594585/how-can-i-hide-section-headers-in-ios-11
        tableView.sectionHeaderHeight = CGFloat(0.01)
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(ConversationViewCell.self, forCellReuseIdentifier: ConversationViewCell.cellIdentifier)
        
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
        dataController.presentWelcomeMessage()
        
        textView.text = ""
        textView.placeholder = NSLocalizedString("Type your question here...", comment: "Placeholder text for input field when user is selecting a topic")

        self.autocompleteHandler = TopicSelectionHandler(withController: self, chatterbox: chatterbox)
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
        
        // Due to silly self-sizing problems with UITableViewCell I am forcing table to redraw itself after data are reloaded
        // This will trigger UIControl to be placed in the cell and update its height
        // Then we need to call beginUpdates() endUpdates() on cell to refresh cell height
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func manageInputControl() {
        if inputState == .inConversation {
            // during conversation we hide the input when displaying any control other than text as the last one
            let count = dataController.controlCount()
            if count > 0, let lastControl = dataController.controlForIndex(0) {
                textView.text = ""
                isTextInputbarHidden = lastControl.controlModel.type != .text
            }
        }
    }
    
    // MARK: - MessageViwController reuse

    func makeOrReuseMessageViewController() -> MessageViewController {
        let messageViewController: MessageViewController
        if let firstUnusedController = messageViewControllersToReuse.first {
            messageViewController = firstUnusedController
            messageViewController.prepareForReuse()
            messageViewControllersToReuse.remove(messageViewController)
        } else {
            messageViewController = MessageViewController(nibName: "MessageViewController", bundle: Bundle(for: type(of: self)))
        }
        
        messageViewController.willMove(toParentViewController: self)
        addChildViewController(messageViewController)
        return messageViewController
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
        let model = TextControlViewModel(label: "", value: inputText)
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
        
        guard let messageViewController = messageViewControllersByIndexPath[indexPath] else {
            return
        }
        
        // prepareForReuse on UITableViewCell is called later than this method, so we need to make sure we will nil-out messageView (that is a view on MessageViewController)
        // otherwise we will end up in a weird state where view is being added to a new cell and then old cell will call prepareForReuse..
        (cell as? ConversationViewCell)?.messageView = nil
        messageViewController.removeFromParentViewController()
        messageViewControllersByIndexPath.removeValue(forKey: indexPath)
        messageViewControllersToReuse.insert(messageViewController)
    }
    
    private func conversationCellForRowAt(_ indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < dataController.controlCount() else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationViewCell.cellIdentifier, for: indexPath) as! ConversationViewCell
        configureConversationCell(cell, at: indexPath)
        return cell
    }
    
    private func configureConversationCell(_ cell: ConversationViewCell, at indexPath:IndexPath) {
        cell.selectionStyle = .none
        
        if let chatMessageModel = dataController.controlForIndex(indexPath.row) {
            let messageViewController = makeOrReuseMessageViewController()
            messageViewControllersByIndexPath[indexPath] = messageViewController
            cell.messageView = messageViewController.view
            messageViewController.didMove(toParentViewController: self)
            messageViewController.model = chatMessageModel
            messageViewController.uiControl?.delegate = self
            cell.transform = self.tableView.transform
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

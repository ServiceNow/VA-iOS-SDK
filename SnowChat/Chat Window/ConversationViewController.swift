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
    
    private let bottomInset: CGFloat = 60
    
    private var inputState = InputState.inTopicSelection
    private var autocompleteHandler: AutoCompleteHandler?

    private let dataController: ChatDataController
    private let chatterbox: Chatterbox

    private var messageViewControllerCache = ChatMessageViewControllerCache()
    private var uiControlCache = ControlCache()
    
    private var canFetchOlderMessages = false
    private var timeLastHistoryFetch: Date = Date()
    private var isLoading = false
    
    override var tableView: UITableView {
        // swiftlint:disable:next force_unwrapping
        return super.tableView!
    }
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
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
        
        setupActivityIndicator()
        setupTableView()
        
        loadHistory()
    }
    
    internal func loadHistory() {
        dataController.loadHistory { (error) in
            if let error = error {
                Logger.default.logError("Error loading history! \(error)")
            }
        }
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
        // see https://stackoverflow.com/questions/46594585/how-can-i-hide-section-headers-in-ios-11
        tableView.sectionHeaderHeight = CGFloat(0.01)
        tableView.estimatedRowHeight = 250
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(ConversationViewCell.self, forCellReuseIdentifier: ConversationViewCell.cellIdentifier)
        tableView.register(ControlViewCell.self, forCellReuseIdentifier: ControlViewCell.cellIdentifier)
        tableView.register(StartTopicDividerCell.self, forCellReuseIdentifier: StartTopicDividerCell.cellIdentifier)
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
        let indexPath = IndexPath(row: index, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? ConversationViewCell else {
            return
        }
        
        cell.messageViewController?.model = model
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })
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
                case .update(let index, let oldModel, let model):
                    guard model.controlModel != nil,
                          oldModel.controlModel != nil else { fatalError("Only control-types allowed in didChangeModel udpates!") }
                    
                    if model.type != oldModel.type || model.isAuxiliary != oldModel.isAuxiliary {
                        self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    } else {
                        updateModel(model, atIndex: index)
                    }
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
    
    func controllerWillLoadContent(_ dataController: ChatDataController) {
        isLoading = true
        showActivityIndicator = true
    }
    
    func controllerDidLoadContent(_ dataController: ChatDataController) {
        isLoading = false
        canFetchOlderMessages = true

        setupInputForState()
        manageInputControl()
        updateTableView()
        
        showActivityIndicator = false
    }
    
    private func updateTableView() {
        tableView.reloadData()
    }
    
    func manageInputControl() {
        // don't process the input control during bulk-load, it will be done at the end
        guard isLoading == false else { return }
        
        switch inputState {
        case  .inConversation:
            // during conversation we hide the input bar unless the last control is an input (TextControl with forInput property set)
            let count = dataController.controlCount()
            if count > 0, let lastControl = dataController.controlForIndex(0) {
                textView.text = ""

                if lastControl.controlModel is TextControlViewModel && lastControl.requiresInput {
                    isTextInputbarHidden = false
                    //textView.becomeFirstResponder()
                } else {
                    isTextInputbarHidden = true
                }
            }
        case .inTopicSelection:
            isTextInputbarHidden = false
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
            break
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
        let model = TextControlViewModel(id: ChatUtil.uuidString(), value: inputText)
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
        if tableView == autoCompletionView {
            return autocompleteHandler?.cellForRowAt(indexPath) ?? UITableViewCell()
        }
        
        guard let chatMessageModel = dataController.controlForIndex(indexPath.row) else {
            return UITableViewCell()
        }
        
        let cell: UITableViewCell
        
        switch chatMessageModel.type {
            
        case .control:
            guard let controlModel = chatMessageModel.controlModel else { return UITableViewCell() }
            if chatMessageModel.isAuxiliary {
                let controlCell = tableView.dequeueReusableCell(withIdentifier: ControlViewCell.cellIdentifier, for: indexPath) as! ControlViewCell
                controlCell.configure(with: controlModel)
                controlCell.control?.delegate = self
                cell = controlCell
            } else {
                let conversationCell = tableView.dequeueReusableCell(withIdentifier: ConversationViewCell.cellIdentifier, for: indexPath) as! ConversationViewCell
                configureConversationCell(conversationCell, messageModel: chatMessageModel, at: indexPath)
                cell = conversationCell
            }
        case .topicDivider:
            let dividerCell = tableView.dequeueReusableCell(withIdentifier: StartTopicDividerCell.cellIdentifier, for: indexPath) as! StartTopicDividerCell
            dividerCell.configure(with: chatMessageModel)
            cell = dividerCell
        }
        
        cell.selectionStyle = .none
        cell.transform = tableView.transform
        return cell
    }
    
    private func conversationCellForRowAt(_ indexPath: IndexPath) -> UITableViewCell {
        guard let chatMessageModel = dataController.controlForIndex(indexPath.row) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationViewCell.cellIdentifier, for: indexPath) as! ConversationViewCell
        configureConversationCell(cell, messageModel: chatMessageModel, at: indexPath)
        return cell
    }
    
    private func configureConversationCell(_ cell: ConversationViewCell, messageModel model: ChatMessageModel, at indexPath: IndexPath) {
        let messageViewController = messageViewControllerCache.cachedViewController(movedToParentViewController: self)
        cell.messageViewController = messageViewController
        messageViewController.configure(withChatMessageModel: model, controlCache: uiControlCache, controlDelegate: self, resourceProvider: chatterbox.apiManager)
        messageViewController.didMove(toParentViewController: self)
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
        guard let conversationCell = cell as? ConversationViewCell,
            let messageViewController = conversationCell.messageViewController else {
            return
        }
        
        messageViewControllerCache.cacheViewController(messageViewController)
        conversationCell.messageViewController = nil
    }
}

extension ConversationViewController: ChatEventListener {
    
    // MARK: - ChatEventListener
    
    func chatterbox(_ chatterbox: Chatterbox, didEstablishUserSession sessionId: String, forChat chatId: String ) {
        // if we were shown before the session was established then we did not load history yet, so do it now
        loadHistory()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topicInfo: TopicInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
                return
        }

        dataController.topicDidStart(topicInfo)
        
        inputState = .inConversation
        setupInputForState()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didResumeTopic topicInfo: TopicInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }
        
        dataController.topicDidResume(topicInfo)
        
        inputState = .inConversation
        setupInputForState()
        manageInputControl()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topicInfo: TopicInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }

        dataController.topicDidFinish(topicInfo)
        
        inputState = .inTopicSelection
        setupInputForState()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTransportStatus transportStatus: TransportStatus, forChat chatId: String) {
        // TODO: is there anything to do here to help the user deal with loss of connectivity?
    }
}

extension ConversationViewController: ControlDelegate, OutputImageControlDelegate {
    
    // MARK: - ControlDelegate
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel) {
        // TODO: how to determine if it was skipped?
        dataController.updateControlData(model, isSkipped: false)
    }
    
    func controlDidFinishImageDownload(_ control: OutputImageControl) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let chatModel = dataController.controlForIndex(indexPath.row) {
            if chatModel.type == .topicDivider {
                return 2
            }
            
            if let imageViewModel = chatModel.controlModel as? OutputImageViewModel, let size = imageViewModel.imageSize {
                return size.height
            }
        }
        return 200
    }
}

extension ConversationViewController: ContextItemProvider {
    
    func contextMenuItems() -> [ContextMenuItem] {
        return dataController.contextMenuItems()
    }
}

extension ConversationViewController {
    
    // MARK: - Activity Indicator
    
    fileprivate func setupActivityIndicator() {
        activityIndicator.color = UIColor.controlTextColor
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
    
    var showActivityIndicator: Bool {
        set(show) {
            if show {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
        get {
            return activityIndicator.isAnimating
        }
    }
}

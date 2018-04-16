//
//  ConversationViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import SlackTextViewController

class ConversationViewController: SLKTextViewController, ViewDataChangeListener, Themeable {
    
    private enum InputState {
        case inSystemTopicSelection     // user can select topic, talk to tagent, or quit
        case inTopicSelection           // user is searching topics
        case inConversation             // user is in an active conversation
        case waitingForAgent            // waiting for an agent to connect
        case inAgentConversation        // in a conversation with an agent
    }
    
    private let bottomInset: CGFloat = 45
    private let estimatedRowHeight: CGFloat = 50
    
    private var inputState = InputState.inTopicSelection {
        didSet {
            setupInputForState()
        }
    }
    
    private var autocompleteHandler: AutoCompleteHandler?

    private let dataController: ChatDataController
    private let chatterbox: Chatterbox

    private var messageViewControllerCache = ChatMessageViewControllerCache()
    private var uiControlCache = ControlCache()
    
    private var canFetchOlderMessages = false
    private var timeLastHistoryFetch: Date = Date()
    private var isLoading = false
    private var defaultMessageHeight: CGFloat?
    private var maxMessageHeight: CGFloat?
    
    private var wasHistoryLoadedForUser: Bool = false
    
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
        
        self.chatterbox.chatEventListeners.addListener(self)
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
        initializeSessionIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let vendorName = chatterbox.session?.settings?.brandingSettings?.headerLabel {
            self.navigationController?.navigationBar.topItem?.title = vendorName
        }
    }
    
    internal func loadHistory() {
        dataController.loadHistory { [weak self] error in
            if let error = error {
                Logger.default.logError("Error loading history! \(error)")
            } else {
                self?.wasHistoryLoadedForUser = true
            }
        }
    }
    
    // MARK: - ContentInset fix
    
    override func viewWillLayoutSubviews() {
        // not calling super to override slack's behavior
        adjustContentInset()
        defaultMessageHeight = tableView.bounds.height * 0.3
        
        let bottomMargin: CGFloat
        if #available(iOS 11.0, *) {
            bottomMargin = tableView.safeAreaInsets.top
        } else {
            // Fallback on earlier versions
            bottomMargin = topLayoutGuide.length
        }
        
        maxMessageHeight = tableView.bounds.height - bottomMargin - 50
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
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(ConversationViewCell.self, forCellReuseIdentifier: ConversationViewCell.cellIdentifier)
        tableView.register(ControlViewCell.self, forCellReuseIdentifier: ControlViewCell.cellIdentifier)
        tableView.register(TopicDividerCell.self, forCellReuseIdentifier: TopicDividerCell.cellIdentifier)
    }
    
    func applyTheme(_ theme: Theme) {
        tableView.backgroundColor = theme.backgroundColor
        self.autoCompletionView.backgroundColor = theme.buttonBackgroundColor
        
        // Might need to apply: https://developer.apple.com/library/content/qa/qa1808/_index.html
        navigationController?.navigationBar.barTintColor = theme.headerBackgroundColor
        textInputbar.backgroundColor = theme.inputBackgroundColor
    }

    private func setupInputForState() {
        switch inputState {
        case .inTopicSelection:
            setupForTopicSelection()
        case .inSystemTopicSelection:
            setupForSystemTopicSelection()
        case .waitingForAgent:
            setupForWaitingOnAgent()
        case .inAgentConversation:
            setupForAgentConversation()
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
    
    fileprivate func setupTextViewForConversation() {
        registerPrefixes(forAutoCompletion: [])
        self.autocompleteHandler = nil
        
        rightButton.isHidden = false
        rightButton.setTitle(NSLocalizedString("Send", comment: "Right button label in conversation mode"), for: .normal)
        
        textView.text = ""
        textView.placeholder = ""
    }
    
    private func setupForConversation() {
        setupTextViewForConversation()
        setTextInputbarHidden(true, animated: true)
    }
    
    private func setupForWaitingOnAgent() {
        setTextInputbarHidden(true, animated: true)
    }
    
    private func setupForAgentConversation() {
        setupTextViewForConversation()
        setTextInputbarHidden(false, animated: true)
    }
    
    // MARK: - ViewDataChangeListener
    
    private func updateModel(_ model: ChatMessageModel, atIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? ConversationViewCell else {
            return
        }
        
        cell.messageViewController?.configure(withChatMessageModel: model,
                                              controlCache: uiControlCache,
                                              controlDelegate: self,
                                              resourceProvider: chatterbox.apiManager)
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
        
        tableView.layoutIfNeeded()
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
                } else {
                    isTextInputbarHidden = true
                }
            }
        case .inTopicSelection, .inAgentConversation:
            isTextInputbarHidden = false
        case .waitingForAgent, .inSystemTopicSelection:
            isTextInputbarHidden = true
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
        guard canFetchOlderMessages,
            Date().timeIntervalSince(timeLastHistoryFetch) > 5.0 else {
                Logger.default.logDebug("Skipping fetch of older messages - last one was \(Date().timeIntervalSince(timeLastHistoryFetch)) ago")
                return
        }
            
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
        case .inAgentConversation:
            // TODO: validate?
            break
        default:
            break
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
        case .inConversation,
             .inAgentConversation:
            dispatchUserInput(inputText)
        default:
            Logger.default.logDebug("Right button or enter pressed: state=\(inputState)")
        }
    }
    
    func dispatchUserInput(_ inputText: String) {
        switch inputState {
        case .inConversation:
            // send the input as a control update
            let model = TextControlViewModel(id: ChatUtil.uuidString(), value: inputText)
            dataController.updateControlData(model, isSkipped: false)
        case .inAgentConversation:
            // send the input as a straight-up data control (not an update)
            let model = TextControlViewModel(id: ChatUtil.uuidString(), value: inputText)
            dataController.sendControlData(model)
            textView.text = ""
        default:
            break
        }
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
            if chatMessageModel.isAuxiliary {
                let controlCell = tableView.dequeueReusableCell(withIdentifier: ControlViewCell.cellIdentifier, for: indexPath) as! ControlViewCell
                controlCell.configure(with: chatMessageModel, resourceProvider: chatterbox.apiManager)
                controlCell.control?.delegate = self
                cell = controlCell
            } else {
                let conversationCell = tableView.dequeueReusableCell(withIdentifier: ConversationViewCell.cellIdentifier, for: indexPath) as! ConversationViewCell
                configureConversationCell(conversationCell, messageModel: chatMessageModel, at: indexPath)
                cell = conversationCell
            }
        case .topicDivider:
            let dividerCell = tableView.dequeueReusableCell(withIdentifier: TopicDividerCell.cellIdentifier, for: indexPath) as! TopicDividerCell
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
        adjustModelSizeIfNeeded(model)
        messageViewController.configure(withChatMessageModel: model,
                                        controlCache: uiControlCache,
                                        controlDelegate: self,
                                        resourceProvider: chatterbox.apiManager)
        messageViewController.didMove(toParentViewController: self)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == autoCompletionView, let handler = autocompleteHandler {
            return handler.viewForHeaderInSection(section)
        } else {
            return nil
        }
    }
    
    // MARK: - Special case for OutputHtmlViewModel..
    private func adjustModelSizeIfNeeded(_ messageModel: ChatMessageModel) {
        guard let outputHtmlModel = messageModel.controlModel as? OutputHtmlControlViewModel,
            let size = outputHtmlModel.size else {
                return
        }
        
        if let messageHeight = defaultMessageHeight, size.height == UIViewNoIntrinsicMetric {
            outputHtmlModel.size = CGSize(width: UIViewNoIntrinsicMetric, height: messageHeight)
        } else if let messageHeight = maxMessageHeight, size.height > messageHeight {
            outputHtmlModel.size = CGSize(width: UIViewNoIntrinsicMetric, height: messageHeight)
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

    func chatterbox(_ chatterbox: Chatterbox, willStartAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }
        
        inputState = .waitingForAgent
        
        dataController.agentTopicWillStart()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didStartAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }

        inputState = .inAgentConversation

        dataController.agentTopicDidStart(agentInfo: agentInfo)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didResumeAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }
        
        if agentInfo.agentId == AgentInfo.IDUNKNOWN {
            // no agent yet, so it is still waiting
            inputState = .waitingForAgent
        } else {
            inputState = .inAgentConversation
            manageInputControl()
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }
        
        inputState = .inTopicSelection

        dataController.agentTopicDidFinish()
    }
    
    private func initializeSessionIfNeeded() {
        if !wasHistoryLoadedForUser {
            loadHistory()
            dataController.loadTheme()
            applyTheme(dataController.theme)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didEstablishUserSession sessionId: String, forChat chatId: String ) {
        initializeSessionIfNeeded()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didRestoreUserSession sessionId: String, forChat chatId: String ) {
        initializeSessionIfNeeded()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topicInfo: TopicInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
                return
        }

        dataController.topicDidStart(topicInfo)
        
        inputState = .inConversation
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didResumeTopic topicInfo: TopicInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }
        
        dataController.topicDidResume(topicInfo)
        
        inputState = .inConversation
        manageInputControl()
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topicInfo: TopicInfo, forChat chatId: String) {
        guard self.chatterbox.id == chatterbox.id else {
            return
        }

        dataController.topicDidFinish()
        
        inputState = .inTopicSelection
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTransportStatus transportStatus: TransportStatus, forChat chatId: String) {
        // TODO: is there anything to do here to help the user deal with loss of connectivity?
    }
}

extension ConversationViewController: ControlDelegate {
    
    // MARK: - ControlDelegate
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel) {
        if let model = model as? ButtonControlViewModel,
            model.value == ChatDataController.showAllTopicsAction,
            let handler = autocompleteHandler as? TopicSelectionHandler {
            
            // show the all-topics list
            handler.showAllTopics()
            return
        }
        
        dataController.updateControlData(model, isSkipped: false)
    }
    
    func controlDidFinishLoading(_ control: ControlProtocol) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let chatModel = dataController.controlForIndex(indexPath.row) {
            if chatModel.type == .topicDivider {
                return TopicDividerCell.dividerHeight
            }
            
            if let viewModel = chatModel.controlModel as? Resizable, let size = viewModel.size {
                return size.height
            }
        }
        
        return estimatedRowHeight
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
        activityIndicator.color = Theme.controlTextColor
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
    
    var showActivityIndicator: Bool {
        set(show) {
            if show {
                view.bringSubview(toFront: activityIndicator)
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
                view.sendSubview(toBack: activityIndicator)
            }
        }
        get {
            return activityIndicator.isAnimating
        }
    }
}

//
//  Chatterbox.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/1/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//
//  Chatterbox instance is created and retained by client that is interested in displaying a chat session
//
//  Client should implement the ChatDataListener protocol to get control messages and implement
//  the ChatEventListener to get converation lifecycle events
//
//  1) Call initializeSession to start login and initiate the system-topic for a user. A ContextualActionMessage is
//  provided upon success. Options for picking a topic are in the messages inputControls.uiMetadata property
//
//  2) After session is initialized, call startTopic, providing a topic name (obtained from the topic information returned
//  from APIManager's suggestTopics or allTopics methods (or any other way of obtaining valid topicNames)
//
//  During the chat session controls are delivered to clients via the chatDataListener, which must be set by the caller.
//  Additionally, chat lifecycle events are deliverd via the chatEventListener, which must also be set by the caller.
//   NOTE: both listeners are easily set when the Chattertbox instance is created via
//         'init(dataListener: ChatDataListener?, eventListener: ChatEventListener?)'
//
//  3) As user interaction takes place, push state changes via
//     'update(control: CongtrolData)'
//  passing a control message with the value set (not the control message is generally a clone of the original control from the server, with
//  the direction changed, a new ID, and the value set)
//
//  After an update is sent to the server, either a new control message will come in, or the topic will end, with the
//  corresponding chatDataListener and chatEventListener methods being called.
//

import Foundation
import AMBClient

enum ChatterboxError: Error {
    case invalidParameter(details: String)
    case invalidCredentials(details: String)
    case unknown(details: String)
}

class Chatterbox {
    let id = ChatUtil.uuidString()
    
    var user: ChatUser?
    var vendor: ChatVendor?
    
    weak var chatDataListener: ChatDataListener?
    weak var chatEventListener: ChatEventListener?
    weak var chatAuthListener: ChatAuthListener?
    
    private struct ConversationContext {
        var topicName: String?
        var sessionId: String?

        var conversationId: String?
        var systemConversationId: String?
    }
    private var conversationContext = ConversationContext()
    internal var contextualActions: ContextualActionMessage?
    
    private let chatStore = ChatDataStore(storeId: "ChatterboxDataStore")
    private(set) var session: ChatSession?
    
    private var chatChannel: String {
        return "/cs/messages/\(chatId)"
    }
    
    internal let chatId = ChatUtil.uuidString()
    private var chatSubscription: NOWAMBSubscription?
    
    internal let instance: ServerInstance
    
    private(set) internal lazy var apiManager: APIManager = {
        return APIManager(instance: instance, transportListener: self)
    }()
    
    private var messageHandler: ((String) -> Void)?
    private var handshakeCompletedHandler: ((ContextualActionMessage?) -> Void)?
    
    internal let logger = Logger.logger(for: "Chatterbox")

    // MARK: - Client Callable methods
    
    init(instance: ServerInstance, dataListener: ChatDataListener? = nil, eventListener: ChatEventListener? = nil) {
        self.instance = instance
        chatDataListener = dataListener
        chatEventListener = eventListener
    }
    
    func initializeSession(forUser: ChatUser, vendor: ChatVendor,
                           success: @escaping (ContextualActionMessage) -> Void,
                           failure: @escaping (Error?) -> Void ) {
        self.user = forUser
        self.vendor = vendor
        
        logIn { error in
            if error == nil {
                self.createChatSession { error in
                    if error == nil {
                        self.performChatHandshake { actionMessage in
                            guard let actionMessage = actionMessage else {
                                failure(ChatterboxError.unknown(details: "Chat Handshake failed for an unknown reason"))
                                return
                            }
                            self.contextualActions = actionMessage
                            
                            self.chatEventListener?.chatterbox(self, didEstablishUserSession: self.session?.id ?? "UNKNOWN_SESSION_ID", forChat: self.chatId)
                            
                            success(actionMessage)
                            return
                        }
                    } else {
                        failure(error)
                    }
                }
            } else {
                failure(error)
            }
        }
        logger.logDebug("initializeAMB returning")
    }
    
    func startTopic(withName: String) throws {
        conversationContext.topicName = withName
        
        if let sessionId = session?.id, let conversationId = conversationContext.systemConversationId {
            messageHandler = startTopicHandler
            
            let startTopic = StartTopicMessage(withSessionId: sessionId, withConversationId: conversationId)
            apiManager.ambClient.sendMessage(startTopic, toChannel: chatChannel, encoder: ChatUtil.jsonEncoder)
            
            // TODO: how do we signal an error?
        } else {
            throw ChatterboxError.invalidParameter(details: "Session must be initialized before startTopic is called")
        }
    }
    
    func lastPendingControlMessage(forConversation conversationId: String) -> ControlData? {
        return chatStore.lastPendingMessage(forConversation: conversationId) as? ControlData
    }
    
    func fetchOlderMessages(_ completion: @escaping (Int) -> Void) {
        // request another page of messages prior to the first message we have
        guard let oldestMessage = chatStore.oldestMessage(),
              let consumerAccountId = session?.user.consumerAccountId  else {
                logger.logError("No oldest message or consumerAccountId in fetchOlderMessages")
                completion(0)
                return
        }

        apiManager.fetchOlderConversations(forConsumer: consumerAccountId, beforeMessage: oldestMessage.messageId, completionHandler: { conversations in
            var count = 0
            
            self.chatDataListener?.chatterbox(self, willLoadConversationsForConsumerAccount: consumerAccountId, forChat: self.chatId)

            conversations.forEach({ [weak self] conversation in
                guard let strongSelf = self else { return }
                
                if conversation.isForSystemTopic() {
                    strongSelf.logger.logInfo("Skipping System Topic conversation in fetchOlderMessages")
                    return
                }
                
                let conversationId = conversation.conversationId
                _ = strongSelf.chatStore.findOrCreateConversation(conversationId)
                
                strongSelf.chatDataListener?.chatterbox(strongSelf, willLoadConversationHistory: conversationId, forChat: strongSelf.chatId)

                conversation.messageExchanges().forEach({ [weak self] exchange in
                    guard let strongSelf = self else { return }

                    strongSelf.storeHistoryAndPublish(exchange, forConversation: conversationId)
                    count += (exchange.response != nil ? 2 : 1)
                })

                strongSelf.chatDataListener?.chatterbox(strongSelf, didLoadConversationHistory: conversationId, forChat: strongSelf.chatId)
            })
            
            self.chatDataListener?.chatterbox(self, didLoadConversationsForConsumerAccount: consumerAccountId, forChat: self.chatId)
            
            completion(count)
        })
    }
    
    func endConversation() {
        let sessionId = conversationContext.sessionId ?? "UNKNOWN_SESSION_ID"
        let conversationId = conversationContext.conversationId ?? "UNKNOWN_CONVERSATION_ID"
        
        handleTopicFinishedAction(TopicFinishedMessage(withSessionId: sessionId, withConversationId: conversationId))
    }
    
    // MARK: - Session Methods
    
    private func logIn(_ completion: @escaping (Error?) -> Void) {
        guard  let user = user, vendor != nil else {
            let error = ChatterboxError.invalidParameter(details: "User and Vendor must be initialized first")
            logger.logError(error.localizedDescription)
            completion(error)
            return
        }
        
        apiManager.logIn(username: user.username, password: user.password ?? "") { [weak self] error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.logger.logInfo("AMB Login failed: \(error)")
                strongSelf.loginFailure()
            } else {
                strongSelf.logger.logInfo("Login succeeded")
            }
            completion(error)
        }
    }
    
    private func loginFailure() {
        // bubble up to Chat Service
        
    }
    
    private func createChatSession(_ completion: @escaping (Error?) -> Void) {
        guard let user = user, let vendor = vendor else {
            logger.logError("User and Vendor must be initialized to create a chat session")
            return
        }

        let sessionInfo = ChatSession(id: UUID().uuidString, user: user, vendor: vendor)
        
        apiManager.startChatSession(with: sessionInfo, chatId: chatId) { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let resultSession):
                strongSelf.session = resultSession
                
                strongSelf.logger.logDebug("--> Chat Session established: sessionId: \(strongSelf.session?.id ?? "NIL") \n consumerAccountId=\(resultSession.user.consumerAccountId)")
            case .failure:
                strongSelf.logger.logError("getSession failed!")
            }
            completion(result.error)
        }
    }
    
    private func setupChatSubscription() {
        chatSubscription = apiManager.ambClient.subscribe(chatChannel) { [weak self] (subscription, message) in
            guard let strongSelf = self else { return }
            
            strongSelf.logger.logDebug(message)
            
            // when AMB gives us a message we dispatch to the current handler
            if let messageHandler = strongSelf.messageHandler {
                messageHandler(message)
            } else {
                strongSelf.logger.logError("No handler set in Chatterbox setupChatSubscription!")
            }
        }
    }
    
    private func performChatHandshake(_ completion: @escaping (ContextualActionMessage?) -> Void) {
        handshakeCompletedHandler = completion
        messageHandler = handshakeHandler
        
        setupChatSubscription()

        if let sessionId = session?.id {
            apiManager.ambClient.sendMessage(SystemTopicPickerMessage(forSession: sessionId), toChannel: chatChannel, encoder: ChatUtil.jsonEncoder)
        }
    }
    
    private func handshakeHandler(_ message: String) {
        let event = ChatDataFactory.actionFromJSON(message)
        guard event.eventType == .channelInit, let initEvent = event as? InitMessage  else {
            return
        }
        
        switch initEvent.data.actionMessage.loginStage {
        case .loginStart:
            logger.logDebug("Handshake START message received")
            startUserSession(withInitEvent: initEvent)
        case .loginFinish:
            logger.logDebug("Handshake FINISH message received: conversationID=\(initEvent.data.conversationId ?? "nil")")
            
            conversationContext.systemConversationId = initEvent.data.conversationId
            conversationContext.sessionId = initEvent.data.sessionId
            
            self.messageHandler = self.topicSelectionHandler
        default:
            logger.logError("Unexpected loginStage: \(initEvent.data.actionMessage.loginStage)")
        }
    }
    
    private func topicSelectionHandler(_ message: String) {
        let choices: ControlData = ChatDataFactory.controlFromJSON(message)
        
        if choices.controlType == .contextualAction {
            if let completion = handshakeCompletedHandler {
                let topicChoices = choices as? ContextualActionMessage
                completion(topicChoices)
            } else {
                logger.logFatal("Could not call user session completion handler: invalid message or no handler provided")
            }
        }
    }
    
    private func startUserSession(withInitEvent initEvent: InitMessage) {
        let initUserEvent = userSessionInitMessage(fromInitEvent: initEvent)
        apiManager.ambClient.sendMessage(initUserEvent, toChannel: chatChannel, encoder: ChatUtil.jsonEncoder)
    }
    
    private func userSessionInitMessage(fromInitEvent initEvent: InitMessage) -> InitMessage {
        var initUserEvent = initEvent
        
        initUserEvent.data.direction = .fromClient
        initUserEvent.data.sendTime = Date()
        initUserEvent.data.actionMessage.loginStage = .loginUserSession
        initUserEvent.data.actionMessage.contextHandshake.vendorId = vendor?.vendorId
        initUserEvent.data.actionMessage.contextHandshake.deviceId = deviceIdentifier()
        initUserEvent.data.actionMessage.consumerAcctId = session?.user.consumerAccountId

        if let request = initUserEvent.data.actionMessage.contextHandshake.serverContextRequest {
            initUserEvent.data.actionMessage.contextHandshake.serverContextResponse = serverContextResponse(fromRequest: request)
        }
        
        return initUserEvent
    }
    
    private func serverContextResponse(fromRequest request: [String: ContextItem]) -> [String: Bool] {
        var response: [String: Bool] = [:]
        
        request.forEach { item in
            // say YES to all requests (for now)
            response[item.key] = true
        }
        return response
    }

    // MARK: - User Topic Methods
    
    private func startTopicHandler(_ message: String) {
        //logger.logDebug("startTopicHandler received: \(message)")
        
        let picker: ControlData = ChatDataFactory.controlFromJSON(message)
        
        if picker.controlType == .topicPicker {
            if let topicPicker = picker as? UserTopicPickerMessage {
                if topicPicker.data.direction == .fromServer {
                    var outgoingMessage = topicPicker
                    outgoingMessage.type = "consumerTextMessage"
                    outgoingMessage.data.direction = .fromClient
                    outgoingMessage.data.richControl?.model = ControlModel(type:"field", name: "Topic")
                    outgoingMessage.data.richControl?.value = conversationContext.topicName
                    
                    messageHandler = startUserTopicHandshakeHandler
                    apiManager.ambClient.sendMessage(outgoingMessage, toChannel: chatChannel, encoder: ChatUtil.jsonEncoder)
                }
            }
        }
    }
    
    private func startUserTopicHandshakeHandler(_ message: String) {
        //logger.logDebug("startUserTopicHandshake received: \(message)")
        
        let actionMessage = ChatDataFactory.actionFromJSON(message)
        
        if actionMessage.eventType == .startUserTopic {
            if let startUserTopic = actionMessage as? StartUserTopicMessage {
                
                // client and server messages are the same, so only look at server responses!
                if startUserTopic.data.direction == .fromServer {
                    let startUserTopicReadyMessage = createStartTopicReadyMessage(startUserTopic: startUserTopic)
                    apiManager.ambClient.sendMessage(startUserTopicReadyMessage, toChannel: chatChannel, encoder: ChatUtil.jsonEncoder)
                }
            }
        } else if actionMessage.eventType == .startedUserTopic {
            if let startUserTopicMessage = actionMessage as? StartedUserTopicMessage {
                
                let actionMessage = startUserTopicMessage.data.actionMessage
        
                logger.logInfo("User Topic Started: \(actionMessage.topicName) - \(actionMessage.topicId) - \(actionMessage.ready ? "Ready" : "Not Ready")")
                
                startUserTopic(topicInfo: TopicInfo(topicId: actionMessage.topicId, conversationId: actionMessage.vendorTopicId))
            }
        }
    }
    
    private func beginConversation(topicInfo: TopicInfo) {
        conversationContext.conversationId = topicInfo.conversationId
        installTopicMessageHandler()
    }

    private func startUserTopic(topicInfo: TopicInfo) {
        beginConversation(topicInfo: topicInfo)
        chatEventListener?.chatterbox(self, didStartTopic: topicInfo, forChat: chatId)        
    }
    
    private func resumeUserTopic(topicInfo: TopicInfo) {
        if conversationContext.conversationId != topicInfo.conversationId {
            beginConversation(topicInfo: topicInfo)
        }
        chatEventListener?.chatterbox(self, didResumeTopic: topicInfo, forChat: chatId)
    }
    
    private func createStartTopicReadyMessage(startUserTopic: StartUserTopicMessage) -> StartUserTopicMessage {
        var startUserTopicReady = startUserTopic
        startUserTopicReady.data.messageId = ChatUtil.uuidString()
        startUserTopicReady.data.sendTime = Date()
        startUserTopicReady.data.direction = .fromClient
        startUserTopicReady.data.actionMessage.ready = true
        return startUserTopicReady
    }
    
    // MARK: User Topic Message Handler Methods
    
    private func installTopicMessageHandler() {
        clearMessageHandlers()
        
        messageHandler = userTopicMessageHandler
    }
    
    private func userTopicMessageHandler(_ message: String) {
        logger.logDebug("userTopicMessage received: \(message)")
        
        if handleEventMessage(message) != true {
            let control = ChatDataFactory.controlFromJSON(message)
            handleControlMessage(control)
        }
    }
    
    internal func finishTopic(_ conversationId: String) {
        let topicInfo = TopicInfo(topicId: "TOPIC_ID", conversationId: conversationId)
        self.chatEventListener?.chatterbox(self, didFinishTopic: topicInfo, forChat: self.chatId)
    }
    
    // MARK: - Incoming messages (Controls from service)
    
    fileprivate func handleEventMessage(_ message: String) -> Bool {
        let action = ChatDataFactory.actionFromJSON(message)
        
        switch action.eventType {
        case ChatterboxActionType.finishedUserTopic:
            handleTopicFinishedAction(action)
        default:
            logger.logInfo("Unhandled event message: \(action.eventType)")
            return false
        }
        return true
    }
    
    fileprivate func handleIncomingControlMessage(_ control: ControlData, forConversation conversationId: String) {
        chatStore.storeControlData(control, forConversation: conversationId, fromChat: self)
        chatDataListener?.chatterbox(self, didReceiveControlMessage: control, forChat: chatId)
    }
    
    fileprivate func handleResponseControlMessage(_ control: ControlData, forConversation conversationId: String) {
        if let lastExchange = chatStore.conversation(forId: conversationId)?.messageExchanges().last, !lastExchange.isComplete {
            if let updatedExchange = chatStore.storeResponseData(control, forConversation: conversationId) {
                chatDataListener?.chatterbox(self, didCompleteMessageExchange: updatedExchange, forChat: conversationId)
            }
        }
    }
    
    fileprivate func handleControlMessage(_ control: ControlData) {
        guard control.controlType != .unknown else {
            handleUnknownControl(control)
            return
        }
        
        if let conversationId = control.conversationId {
            switch control.direction {
            case .fromClient:
                handleResponseControlMessage(control, forConversation: conversationId)
            case .fromServer:
                handleIncomingControlMessage(control, forConversation: conversationId)
            }
        }
    }
    
    fileprivate func handleUnknownControl(_ control: ControlData) {
        logger.logError("*** Ignoring unrecognized control type \(control.controlType) ***")
    }
    
    fileprivate func handleTopicFinishedAction(_ action: ActionData) {
        if let topicFinishedMessage = action as? TopicFinishedMessage {
            conversationContext.conversationId = nil
            
            saveDataToPersistence()
            
            let topicInfo = TopicInfo(topicId: "TOPIC_ID", conversationId: topicFinishedMessage.data.conversationId ?? "CONVERSATION_ID")
            chatEventListener?.chatterbox(self, didFinishTopic: topicInfo, forChat: chatId)
        }
    }
    
    // MARK: - Update Controls (outgoing from user)
    
    func update(control: ControlData) {
        // based on type, cast the value and push to the store, then send back to service via AMB
        let type = control.controlType
        switch type {
        case .boolean:
            updateBooleanControl(control)
        case .input:
            updateInputControl(control)
        case .picker:
            updatePickerControl(control)
        case .multiSelect:
            updateMultiSelectControl(control)
        case .multiPart:
            updateMultiPartControl(control)
        default:
            logger.logError("Unrecognized control type - skipping: \(type)")
            return
        }
    }
    
    fileprivate func updateRichControlData<T>(_ inputMessage: RichControlData<T>) -> RichControlData<T> {
        var message = inputMessage
        message.direction = .fromClient
        message.sendTime = Date()
        return message
    }
    
    fileprivate func publishControlUpdate<T: ControlData>(_ message: T, forConversation conversationId: String) {
        apiManager.ambClient.sendMessage(message, toChannel: chatChannel, encoder: ChatUtil.jsonEncoder)
    }
    
    fileprivate func updateBooleanControl(_ control: ControlData) {
        if var booleanControl = control as? BooleanControlMessage, let conversationId = booleanControl.data.conversationId {
            booleanControl.data = updateRichControlData(booleanControl.data)
            publishControlUpdate(booleanControl, forConversation: conversationId)
        }
    }
    
    fileprivate func updateInputControl(_ control: ControlData) {
        if var inputControl = control as? InputControlMessage, let conversationId = inputControl.data.conversationId {
            inputControl.data = updateRichControlData(inputControl.data)
            publishControlUpdate(inputControl, forConversation: conversationId)
        }
    }
    
    fileprivate func updatePickerControl(_ control: ControlData) {
        if var pickerControl = control as? PickerControlMessage, let conversationId = pickerControl.data.conversationId {
            pickerControl.data = updateRichControlData(pickerControl.data)
            publishControlUpdate(pickerControl, forConversation: conversationId)
        }
    }

    fileprivate func updateMultiSelectControl(_ control: ControlData) {
        if var multiSelectControl = control as? MultiSelectControlMessage, let conversationId = multiSelectControl.data.conversationId {
            multiSelectControl.data = updateRichControlData(multiSelectControl.data)
            publishControlUpdate(multiSelectControl, forConversation: conversationId)
        }
    }
    
    fileprivate func updateMultiPartControl(_ control: ControlData) {
        if var multiPartControl = control as? MultiPartControlMessage, let conversationId = multiPartControl.data.conversationId {
            multiPartControl.data = updateRichControlData(multiPartControl.data)
            publishControlUpdate(multiPartControl, forConversation: conversationId)
        }
    }
    
    func currentConversationHasControlData(forId messageId: String) -> Bool {
        guard let conversationId = conversationContext.conversationId else { return false }
        
        let message = chatStore.conversation(forId: conversationId)?.messageExchanges().first(where: { (exchange) -> Bool in
            exchange.message.messageId == messageId
        })
        
        return message != nil
    }
    
    // MARK: - Cleanup
    
    private func clearMessageHandlers() {
        messageHandler = nil
        handshakeCompletedHandler = nil
    }
}

extension Chatterbox {

    // MARK: - Sync Current Conversation
    
    fileprivate func syncConversationState(_ conversation: Conversation) {
        let conversationId = conversation.conversationId
        
        switch conversation.state {
        case .inProgress:
            logger.logInfo("Conversation \(conversationId) is in progress")
            let topicInfo = TopicInfo(topicId: "TOPIC_ID", conversationId: conversationId)
            resumeUserTopic(topicInfo: topicInfo)
        case .completed:
            logger.logInfo("Conversation is no longer in progress - ending current conversations")
            finishTopic(conversationId)
        case .unknown:
            logger.logError("Unknown conversation state in syncConversation!")
        }
    }
    
    fileprivate func syncNoConversationsReturned() {
        // if no messages were returned, then we have the latest messages, just need to update the input mode
        logger.logDebug("Sync with NO conversation returned - nothing to do!")
    }
    
    fileprivate func syncCurrentConversation(_ receivedConversation: Conversation, _ newestExchange: MessageExchange) {
        guard let firstReceivedExchange = receivedConversation.messageExchanges().first,
              let receivedResponseId = firstReceivedExchange.response?.messageId,
              let ourResponseId = newestExchange.response?.messageId,
              receivedResponseId == ourResponseId  else {
                // responses do not match!
                return
        }
        
        // our last response matches the info we received, we are in sync!
        logger.logInfo("Conversation messages in sync!")
        syncConversationState(receivedConversation)
    }
    
    func syncConversation(_ completion: @escaping (Int) -> Void) {
        // get the newest message and see if there are any messages newer than that for this consumer
        //
        guard let consumerAccountId = session?.user.consumerAccountId else {
            logger.logError("No consumerAccountId in syncConversation!")
            return
        }
        guard let conversationId = conversationContext.conversationId,
              let conversation = chatStore.conversation(forId: conversationId),
              let newestExchange = conversation.newestExchange() else {
            logger.logError("Could not determine last message ID")
            completion(0)
            return
        }
        
        let newestMessage = newestExchange.message
                
        apiManager.fetchNewerConversations(forConsumer: consumerAccountId, afterMessage: newestMessage.messageId, completionHandler: { [weak self] conversationsFromService in
            guard let strongSelf = self else { return }

            // HACK: service is returning user and system conversations, so we remove all system topics here
            //       remove this when the service is fixed
            let conversations = strongSelf.filterSystemTopics(conversationsFromService)
            
            if conversations.count == 0 {
                strongSelf.syncNoConversationsReturned()
                completion(0)
                
            } else if conversations.count == 1 && conversations.first?.conversationId == conversationId {
                // we got back something for the current conversation; make sure it matches the response we have
                guard let receivedConversation = conversations.first else { return }
                strongSelf.syncCurrentConversation(receivedConversation, newestExchange)
                completion(1)
                
            } else {
                // if we are here we have to reload everything
                strongSelf.clearAndReloadFromPersistence(completionHandler: { (error) in
                    let count = strongSelf.chatStore.conversations.count
                    completion(count)
                })
            }
        })
    }

    internal func flattenMessageExchanges(_ exchanges: [MessageExchange]) -> [ControlData] {
        var messages = [ControlData]()
        
        exchanges.forEach({ exchange in
            messages.append(exchange.message)
            if let response = exchange.response {
                messages.append(response)
            }
        })
        
        return messages
    }
    
    internal func addExchanges(_ messageExchanges: [MessageExchange], newerThan subjectExchange: MessageExchange?, forConversation conversationId: String) {
        var newerExchanges: [MessageExchange]
        
        if let subjectExchange = subjectExchange {
            newerExchanges = messageExchanges.filter { exchange -> Bool in
                return exchange.message.messageTime.timeIntervalSince(subjectExchange.message.messageTime) > 0
            }
        } else {
            // nothing to compare to, so use them all
            newerExchanges = messageExchanges
        }
        
        guard newerExchanges.count > 0 else {
            logger.logDebug("no messages newer than what we have: already in sync")
            return
        }
        
        newerExchanges.forEach { exchange in
            self.storeHistoryAndPublish(exchange, forConversation: conversationId)
        }
    }
}

extension Chatterbox {
    
    // MARK: - Persistence Methods
    
    internal func saveDataToPersistence() {
        do {
            try chatStore.save()
        } catch let error {
            logger.logError("Exception storing chatStore: \(error)")
        }
    }
    
    internal func clearAndReloadFromPersistence(completionHandler: @escaping (Error?) -> Void) {
        chatStore.reset()
        loadDataFromPersistence(completionHandler: completionHandler)
    }
    
    internal func loadDataFromPersistence(completionHandler: @escaping (Error?) -> Void) {
        // TODO: load locally stored history and synchronize with the server
        //       for now we just pull from server, no local store
        /*
        do {
            let conversations = try chatStore.load()
        } catch let error {
            logger.logError("Exception loading chatStore: \(error)")
        }
        */
        
        refreshConversations(completionHandler: completionHandler)
    }
    
    internal func refreshConversations(completionHandler: @escaping (Error?) -> Void) {
        
        if let consumerId = session?.user.consumerAccountId {
            logger.logDebug("--> Loading conversations for \(consumerId)")
            
            self.chatDataListener?.chatterbox(self, willLoadConversationsForConsumerAccount: consumerId, forChat: self.chatId)

            apiManager.fetchConversations(forConsumer: consumerId, completionHandler: { (conversationsFromService) in
                
                // HACK: service is returning user and system conversations, so we remove all system topics here
                //       remove this when the service is fixed
                let conversations = self.filterSystemTopics(conversationsFromService)
                self.logger.logDebug(" --> loaded \(conversationsFromService.count) conversations, \(conversations.count) are for user")

                let lastConversation = conversations.last
                
                conversations.forEach { conversation in
                    let conversationId = conversation.conversationId
                    self.logger.logDebug("--> Conversation \(conversationId) refreshed: \(conversation)")
                    
                    self.chatDataListener?.chatterbox(self, willLoadConversation: conversationId, forChat: self.chatId)
                    self.storeConversationAndPublish(conversation)
                    self.chatDataListener?.chatterbox(self, didLoadConversation: conversationId, forChat: self.chatId)
                    
                    if conversation.conversationId == lastConversation?.conversationId {
                        self.syncConversationState(conversation)
                    }
                }
                
                self.chatDataListener?.chatterbox(self, didLoadConversationsForConsumerAccount: consumerId, forChat: self.chatId)
                
                completionHandler(nil)
            })
        } else {
            logger.logError("No consumer Account ID, cannot load data from service")
            completionHandler(ChatterboxError.invalidParameter(details: "No ConsumerAccountId set in refreshConversations"))
        }
    }
    
    internal func filterSystemTopics(_ conversations: [Conversation]) -> [Conversation] {
        return conversations.filter({ conversation -> Bool in
            return conversation.isForSystemTopic() == false
        })
    }
    
    internal func storeHistoryAndPublish(_ exchange: MessageExchange, forConversation conversationId: String) {
        chatStore.storeHistory(exchange, forConversation: conversationId)
        chatDataListener?.chatterbox(self, didReceiveHistory: exchange, forChat: chatId)
    }
    
    internal func storeConversationAndPublish(_ conversation: Conversation) {
        chatStore.storeConversation(conversation)
        
        conversation.messageExchanges().forEach { (exchange) in
            notifyMessageExchange(exchange)
        }
    }

    internal func notifyMessageExchange(_ exchange: MessageExchange) {
        logger.logDebug("--> Notifying MessageExchange: message=\(exchange.message.controlType) | response=\(exchange.response?.controlType ?? .unknown)")
        
        let message = exchange.message
        
        notifyMessage(message)
        
        if let response = exchange.response {
            notifyResponse(response, exchange: exchange)
        }
    }
    
    internal func notifyMessage(_ message: ControlData) {
        guard let chatDataListener = chatDataListener else {
            logger.logError("No ChatDataListener in NotifyControlReceived")
            return
        }

        chatDataListener.chatterbox(self, didReceiveControlMessage: message, forChat: chatId)
    }
    
    internal func notifyResponse(_ response: ControlData, exchange: MessageExchange) {
        guard let chatDataListener = chatDataListener else {
            logger.logError("No ChatDataListener in notifyResponseReceived")
            return
        }
        
        chatDataListener.chatterbox(self, didCompleteMessageExchange: exchange, forChat: chatId)
    }
}

extension Chatterbox: TransportStatusListener {
    
    // MARK: - handle transport notifications
    
    func transportDidBecomeUnavailable() {
        logger.logInfo("Network unavailable....")

        chatEventListener?.chatterbox(self, didReceiveTransportStatus: .unreachable, forChat: chatId)
    }
    
    private static var alreadySynchronizing = false
    
    func transportDidBecomeAvailable() {
        chatEventListener?.chatterbox(self, didReceiveTransportStatus: .reachable, forChat: chatId)

        guard !Chatterbox.alreadySynchronizing, conversationContext.conversationId != nil else { return }
        
        logger.logInfo("Synchronizing conversations due to transport becoming available")
        Chatterbox.alreadySynchronizing = true
        syncConversation { count in
            Chatterbox.alreadySynchronizing = false
        }
    }
    
    func authorizationFailure() {
        logger.logInfo("Authorization failed!")
        chatAuthListener?.authorizationFailed()
    }
}

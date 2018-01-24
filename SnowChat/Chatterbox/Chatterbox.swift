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
//  2) After session is initialized, call startTopic, providing a topic name (obtained from the to
//  During the chat session controls are delivered to clients via the chatDataListener, which must be set by the caller
//  Additionally, chat lifecycle events are deliverd via the chatEventListener, which must also be set by the caller
//   NOTE: both listeners are easily set when the Chattertbox instance is created via
//         'init(dataListener: ChatDataListener?, eventListener: ChatEventListener?)'
//
//  3) As user interaction takes place, push state changes via
//     'update(control controlId: String, ofType: CBControlType, withValue: Any)', passing the original
//     control ID and the user-entered value
//

import Foundation
import AMBClient

enum ChatterboxError: Error {
    case invalidParameter(details: String)
    case invalidCredentials(details: String)
    case unknown(details: String)
}

class Chatterbox {
    let id = CBData.uuidString()
    
    var user: CBUser?
    var vendor: CBVendor?
    
    weak var chatDataListener: ChatDataListener?
    weak var chatEventListener: ChatEventListener?
    
    private struct ConversationContext {
        var topicName: String?
        var conversationId: String?
    }
    private var conversationContext = ConversationContext()
    
    private let chatStore = ChatDataStore(storeId: "ChatterboxDataStore")
    private(set) var session: CBSession?
    
    private var chatChannel: String {
        return "/cs/messages/\(chatId)"
    }
    
    private let chatId = CBData.uuidString()
    private var chatSubscription: NOWAMBSubscription?
    
    private let instance: ServerInstance
    
    private(set) internal lazy var apiManager: APIManager = {
        return APIManager(instance: instance)
    }()
    
    private var messageHandler: ((String) -> Void)?
    private var handshakeCompletedHandler: ((ContextualActionMessage?) -> Void)?
    
    private let logger = Logger.logger(for: "Chatterbox")

    // MARK: - Client Callable methods
    
    init(instance: ServerInstance, dataListener: ChatDataListener? = nil, eventListener: ChatEventListener? = nil) {
        self.instance = instance
        chatDataListener = dataListener
        chatEventListener = eventListener
    }
    
    func initializeSession(forUser: CBUser, vendor: CBVendor,
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
        
        if let sessionId = session?.id, let conversationId = conversationContext.conversationId {
            messageHandler = startTopicHandler
            
            let startTopic = StartTopicMessage(withSessionId: sessionId, withConversationId: conversationId)
            apiManager.ambClient.sendMessage(startTopic, toChannel: chatChannel, encoder: CBData.jsonEncoder)
            
            // TODO: how do we signal an error?
        } else {
            throw ChatterboxError.invalidParameter(details: "Session must be initialized before startTopic is called")
        }
    }
    
    func lastPendingControlMessage(forConversation conversationId: String) -> CBControlData? {
        return chatStore.lastPendingMessage(forConversation: conversationId) as? CBControlData
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
            
            conversations.forEach({ [weak self] conversation in
                guard let strongSelf = self else { return }
                
                if conversation.isForSystemTopic() {
                    strongSelf.logger.logInfo("Skipping System Topic conversation in fetchOlderMessages")
                    return
                }
                
                _ = strongSelf.chatStore.findOrCreateConversation(conversation.uniqueId)
                
                conversation.messageExchanges().reversed().forEach({ [weak self] exchange in
                    guard let strongSelf = self else { return }

                    if exchange.isComplete {
                        strongSelf.storeHistoryAndPublish(exchange, forConversation: conversation.uniqueId)
                        count += (exchange.response != nil ? 2 : 1)
                    }
                })
            })
            
            completion(count)
        })
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
            if let error = error {
                self?.logger.logInfo("AMB Login failed: \(error)")
            } else {
                self?.logger.logInfo("Login succeeded")
            }
            completion(error)
        }
    }
    
    private func createChatSession(_ completion: @escaping (Error?) -> Void) {
        guard let user = user, let vendor = vendor else {
            logger.logError("User and Vendor must be initialized to create a chat session")
            return
        }

        let sessionInfo = CBSession(id: UUID().uuidString, user: user, vendor: vendor)
        
        apiManager.startChatSession(with: sessionInfo, chatId: chatId) { [weak self] result in
            switch result {
            case .success(let resultSession):
                self?.session = resultSession
                self?.logger.logDebug("--> Chat Session established: consumerAccountId=\(resultSession.user.consumerAccountId)")
            case .failure:
                self?.logger.logError("getSession failed!")
            }
            completion(result.error)
        }
    }
    
    private func setupChatSubscription() {
        chatSubscription = apiManager.ambClient.subscribe(chatChannel) { [weak self] (subscription, message) in
            //self?.logger.logDebug(message)
            
            // when AMB gives us a message we dispatch to the current handler
            if let messageHandler = self?.messageHandler {
                messageHandler(message)
            } else {
                self?.logger.logError("No handler set in Chatterbox setupChatSubscription!")
            }
        }
    }
    
    private func performChatHandshake(_ completion: @escaping (ContextualActionMessage?) -> Void) {
        handshakeCompletedHandler = completion
        messageHandler = handshakeHandler
        
        setupChatSubscription()

        if let sessionId = session?.id {
            apiManager.ambClient.sendMessage(SystemTopicPickerMessage(forSession: sessionId), toChannel: chatChannel, encoder: CBData.jsonEncoder)
        }
    }
    
    private func handshakeHandler(_ message: String) {
        let event = CBDataFactory.actionFromJSON(message)
        
        if event.eventType == .channelInit, let initEvent = event as? InitMessage {
            if initEvent.data.actionMessage.loginStage == MessageConstants.loginStart.rawValue {
                logger.logDebug("Handshake START message received")
                startUserSession(withInitEvent: initEvent)
            } else if initEvent.data.actionMessage.loginStage == MessageConstants.loginFinish.rawValue {
                logger.logDebug("Handshake FINISH message received: conversationID=\(initEvent.data.conversationId ?? "nil")")
                
                conversationContext.conversationId = initEvent.data.conversationId
                
                loadDataFromPersistence { error in
                    guard error == nil else {
                        self.logger.logDebug("Error in loading from persistence: \(error.debugDescription)")
                        
                        if let completion = self.handshakeCompletedHandler {
                            completion(nil)
                        }
                        return
                    }

                    // handshake done, setup handler for the topic selection
                    //  NOTE: handshakeCompletedHandler is called after topic selection, via the topicSelectionHandler
                    self.messageHandler = self.topicSelectionHandler
                }
            }
        }
    }
    
    private func topicSelectionHandler(_ message: String) {
        let choices: CBControlData = CBDataFactory.controlFromJSON(message)
        
        if choices.controlType == .contextualActionMessage {
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
        apiManager.ambClient.sendMessage(initUserEvent, toChannel: chatChannel, encoder: CBData.jsonEncoder)
    }
    
    private func userSessionInitMessage(fromInitEvent initEvent: InitMessage) -> InitMessage {
        var initUserEvent = initEvent
        
        initUserEvent.data.direction = .fromClient
        initUserEvent.data.sendTime = Date()
        initUserEvent.data.actionMessage.loginStage = MessageConstants.loginUserSession.rawValue
        initUserEvent.data.actionMessage.contextHandshake.vendorId = vendor?.vendorId
        initUserEvent.data.actionMessage.contextHandshake.deviceId = deviceIdentifier()
        
        if let request = initUserEvent.data.actionMessage.contextHandshake.serverContextRequest {
            initUserEvent.data.actionMessage.contextHandshake.serverContextResponse = serverContextResponse(fromRequest: request)
        }
        return initUserEvent
    }
    
    // MARK: - User Topic Methods
    
    private func startTopicHandler(_ message: String) {
        //logger.logDebug("startTopicHandler received: \(message)")
        
        let picker: CBControlData = CBDataFactory.controlFromJSON(message)
        
        if picker.controlType == .topicPicker {
            if let topicPicker = picker as? UserTopicPickerMessage {
                if topicPicker.data.direction == .fromServer {
                    var outgoingMessage = topicPicker
                    outgoingMessage.type = "consumerTextMessage"
                    outgoingMessage.data.direction = .fromClient
                    outgoingMessage.data.richControl?.model = ControlModel(type:"field", name: "Topic")
                    outgoingMessage.data.richControl?.value = conversationContext.topicName
                    
                    messageHandler = startUserTopicHandshakeHandler
                    apiManager.ambClient.sendMessage(outgoingMessage, toChannel: chatChannel, encoder: CBData.jsonEncoder)
                }
            }
        }
    }
    
    private func startUserTopicHandshakeHandler(_ message: String) {
        //logger.logDebug("startUserTopicHandshake received: \(message)")
        
        let actionMessage = CBDataFactory.actionFromJSON(message)
        
        if actionMessage.eventType == .startUserTopic {
            if let startUserTopic = actionMessage as? StartUserTopicMessage {
                
                // client and server messages are the same, so only look at server responses!
                if startUserTopic.data.direction == .fromServer {
                    let startUserTopicReadyMessage = createStartTopicReadyMessage(startUserTopic: startUserTopic)
                    apiManager.ambClient.sendMessage(startUserTopicReadyMessage, toChannel: chatChannel, encoder: CBData.jsonEncoder)
                }
            }
        } else if actionMessage.eventType == .startedUserTopic {
            if let startedUserTopic = actionMessage as? StartedUserTopicMessage {
                
                let actionMessage = startedUserTopic.data.actionMessage
                logger.logInfo("User Topic Started: \(actionMessage.topicName) - \(actionMessage.topicId) - \(actionMessage.ready ? "Ready" : "Not Ready")")
                
                chatEventListener?.chatterbox(self, didStartTopic: startedUserTopic, forChat: chatId)

                installTopicMessageHandler()
            }
        }
    }
    
    private func createStartTopicReadyMessage(startUserTopic: StartUserTopicMessage) -> StartUserTopicMessage {
        var startUserTopicReady = startUserTopic
        startUserTopicReady.data.messageId = CBData.uuidString()
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
            let control = CBDataFactory.controlFromJSON(message)
            handleControlMessage(control)
        }
    }
    
    // MARK: - Incoming messages from AMB
    
    fileprivate func handleEventMessage(_ message: String) -> Bool {
        let action = CBDataFactory.actionFromJSON(message)
        
        switch action.eventType {
        case CBActionEventType.finishedUserTopic:
            handleTopicFinishedAction(action)
        default:
            logger.logInfo("Unhandled event message: \(action.eventType)")
            return false
        }
        return true
    }
    
    fileprivate func handleControlMessage(_ control: CBControlData) {
        
        guard control.controlType != .unknown else {
            handleUnknownControl(control)
            return
        }
        
        if let conversationId = control.conversationId {
            chatStore.storeControlData(control, forConversation: conversationId, fromChat: self)
            chatDataListener?.chatterbox(self, didReceiveControlMessage: control, forChat: chatId)
        }
    }
    
    fileprivate func handleUnknownControl(_ control: CBControlData) {
        logger.logInfo("Ignoring unrecognized control type \(control.controlType)")
    }
    
    fileprivate func handleTopicFinishedAction(_ action: CBActionMessageData) {
        if let topicFinishedMessage = action as? TopicFinishedMessage {
            saveDataToPersistence()
            chatEventListener?.chatterbox(self, didFinishTopic: topicFinishedMessage, forChat: chatId)
        }
    }
    
    // MARK: - Update Control Methods
    
    func update(control: CBControlData) {
        guard let conversationId = control.conversationId else { fatalError("No conversationId for control in update method!") }
        
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
        default:
            logger.logInfo("Unrecognized control type - skipping: \(type)")
            return
        }
        
        if let lastExchange = chatStore.conversation(forId: conversationId)?.messageExchanges().last {
            chatDataListener?.chatterbox(self, didCompleteMessageExchange: lastExchange, forChat: conversationId)
        }
    }
    
    fileprivate func updateRichControlData<T>(_ inputMessage: RichControlData<T>) -> RichControlData<T> {
        var message = inputMessage
        message.direction = .fromClient
        message.sendTime = Date()
        return message
    }
    
    func storeAndPublish<T: CBControlData>(_ message: T, forConversation conversationId: String) {
        chatStore.storeResponseData(message, forConversation: conversationId)
        apiManager.ambClient.sendMessage(message, toChannel: chatChannel, encoder: CBData.jsonEncoder)
    }
    
    fileprivate func updateBooleanControl(_ control: CBControlData) {
        if var booleanControl = control as? BooleanControlMessage, let conversationId = booleanControl.data.conversationId {
            booleanControl.data = updateRichControlData(booleanControl.data)
            storeAndPublish(booleanControl, forConversation: conversationId)
        }
    }
    
    fileprivate func updateInputControl(_ control: CBControlData) {
        if var inputControl = control as? InputControlMessage, let conversationId = inputControl.data.conversationId {
            inputControl.data = updateRichControlData(inputControl.data)
            storeAndPublish(inputControl, forConversation: conversationId)
        }
    }
    
    fileprivate func updatePickerControl(_ control: CBControlData) {
        if var pickerControl = control as? PickerControlMessage, let conversationId = pickerControl.data.conversationId {
            pickerControl.data = updateRichControlData(pickerControl.data)
            storeAndPublish(pickerControl, forConversation: conversationId)
        }
    }

    fileprivate func updateMultiSelectControl(_ control: CBControlData) {
        if var multiSelectControl = control as? MultiSelectControlMessage, let conversationId = multiSelectControl.data.conversationId {
            multiSelectControl.data = updateRichControlData(multiSelectControl.data)
            storeAndPublish(multiSelectControl, forConversation: conversationId)
        }
    }

    // MARK: - Persistence Methods
    
    private func saveDataToPersistence() {
        do {
            try chatStore.save()
        } catch let error {
            logger.logError("Exception storing chatStore: \(error)")
        }
    }
    
    private func loadDataFromPersistence(completionHandler: @escaping (Error?) -> Void) {
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
    
    private func refreshConversations(completionHandler: @escaping (Error?) -> Void) {
        
        // HACK - work around consumerAccountId issues for testing...
//        let correctConsumerAccountId = session?.user.consumerAccountId
//        session?.user.consumerAccountId = "5b050e0973730300d63a566a4cf6a703"
        
        if let consumerId = session?.user.consumerAccountId {
            logger.logDebug("--> Loading conversations for \(consumerId)")
            
            apiManager.fetchConversations(forConsumer: consumerId, completionHandler: { (conversations) in
                self.logger.logDebug(" --> loaded \(conversations.count) conversations")
                
                conversations.forEach { conversation in
                    if conversation.isForSystemTopic() {
                        self.logger.logInfo("Skipping conversation from system topic in refreshConversations")
                        return
                    }
                    
                    self.logger.logDebug("--> Conversation \(conversation.uniqueId) refreshed: \(conversation)")
                    self.storeConversationAndPublish(conversation)
                }
                completionHandler(nil)
            })
        } else {
            logger.logError("No consumer Account ID, cannot load data from service")
            completionHandler(ChatterboxError.invalidParameter(details: "No ConsumerAccountId set in refreshConversations"))
        }
    }
    
    fileprivate func storeHistoryAndPublish(_ exchange: MessageExchange, forConversation conversationId: String) {
        chatStore.storeHistory(exchange, forConversation: conversationId)
        chatDataListener?.chatterbox(self, didReceiveHistory: exchange, forChat: chatId)
    }
    
    fileprivate func notifyMessageExchange(_ exchange: MessageExchange) {
        let message = exchange.message
        
        notifyControlReceived(message)
        
        if let response = exchange.response {
            notifyResponseReceived(response, exchange: exchange)
        }
    }
    
    private func storeConversationAndPublish(_ conversation: Conversation) {
        chatStore.storeConversation(conversation)
        
        chatDataListener?.chatterbox(self, willLoadConversation: conversation.uniqueId, forChat: chatId)

        conversation.messageExchanges().forEach { (exchange) in
            // NOTE: we only process completed message exchanges, since incomplete ones will render incorrectly
            //       and we will get the completed version (if it exists) via subsequent history calls
            if exchange.isComplete {
                notifyMessageExchange(exchange)
            }
        }
        
        chatDataListener?.chatterbox(self, didLoadConversation: conversation.uniqueId, forChat: chatId)
    }
    
    fileprivate func notifyControlReceived(_ message: CBControlData) {
        guard let chatDataListener = chatDataListener else {
            logger.logError("No ChatDataListener in NotifyControlReceived")
            return
        }

        chatDataListener.chatterbox(self, didReceiveControlMessage: message, forChat: chatId)
    }
    
    fileprivate func notifyResponseReceived(_ response: CBControlData, exchange: MessageExchange) {
        guard let chatDataListener = chatDataListener else {
            logger.logError("No ChatDataListener in notifyResponseReceived")
            return
        }
        
        chatDataListener.chatterbox(self, didCompleteMessageExchange: exchange, forChat: chatId)
    }
    
    // MARK: - Cleanup
    
    private func clearMessageHandlers() {
        messageHandler = nil
        handshakeCompletedHandler = nil
    }
}

private func serverContextResponse(fromRequest request: [String: ContextItem]) -> [String: Bool] {
    var response: [String: Bool] = [:]
    
    request.forEach { item in
        // say YES to all requests (for now)
        response[item.key] = true
    }
    return response
}

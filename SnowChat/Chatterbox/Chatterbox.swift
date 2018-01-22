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
    case invalidCredentials
    case unknown
}

class Chatterbox {
    let id = CBData.uuidString()
    
    var user: CBUser?
    var vendor: CBVendor?
    
    weak var chatDataListener: ChatDataListener?
    weak var chatEventListener: ChatEventListener?
    
    // MARK: Client Callable methods
    
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
                            success(actionMessage)
                            return
                        }
                        // TODO: how do we detect an error here? timeout?
                        // if the ChatServer doesn't send back anything to complete
                        // the handhake we will just sit here waiting...
                        
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
    
    func update(control: CBControlData) {
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
    }
    
    func updateMessage<T>(_ inputMessage: RichControlData<T>) -> RichControlData<T> {
        var message = inputMessage
        message.direction = .fromClient
        message.sendTime = Date()
        return message
    }
    
    func storeAndPublish<T: CBControlData>(_ message: T, forConversation conversationId: String) {
        chatStore.storeResponseData(message, forConversation: conversationId)
        apiManager.ambClient.sendMessage(message, toChannel: chatChannel, encoder: CBData.jsonEncoder)
    }
    
    // MARK: internal properties and methods
    
    fileprivate func updateBooleanControl(_ control: CBControlData) {
        if var booleanControl = control as? BooleanControlMessage, let conversationId = booleanControl.data.conversationId {
            booleanControl.data = updateMessage(booleanControl.data)
            storeAndPublish(booleanControl, forConversation: conversationId)
            
            if let lastExchange = chatStore.conversation(forId: conversationId)?.messageExchanges().last {
                chatDataListener?.chatterbox(self, didCompleteBooleanExchange: lastExchange, forChat: conversationId)
            }
        }
    }
    
    fileprivate func updateInputControl(_ control: CBControlData) {
        if var inputControl = control as? InputControlMessage, let conversationId = inputControl.data.conversationId {
            inputControl.data = updateMessage(inputControl.data)
            storeAndPublish(inputControl, forConversation: conversationId)
            
            if let lastExchange = chatStore.conversation(forId: conversationId)?.messageExchanges().last {
                chatDataListener?.chatterbox(self, didCompleteInputExchange: lastExchange, forChat: conversationId)
            }
        }
    }
    
    fileprivate func updatePickerControl(_ control: CBControlData) {
        if var pickerControl = control as? PickerControlMessage, let conversationId = pickerControl.data.conversationId {
            pickerControl.data = updateMessage(pickerControl.data)
            storeAndPublish(pickerControl, forConversation: conversationId)
            
            if let lastExchange = chatStore.conversation(forId: conversationId)?.messageExchanges().last {
                chatDataListener?.chatterbox(self, didCompletePickerExchange: lastExchange, forChat: conversationId)
            }
        }
    }
    
    fileprivate func updateMultiSelectControl(_ control: CBControlData) {
        if var multiSelectControl = control as? MultiSelectControlMessage, let conversationId = multiSelectControl.data.conversationId {
            multiSelectControl.data = updateMessage(multiSelectControl.data)
            storeAndPublish(multiSelectControl, forConversation: conversationId)
            
            if let lastExchange = chatStore.conversation(forId: conversationId)?.messageExchanges().last {
                chatDataListener?.chatterbox(self, didCompleteMultiSelectExchange: lastExchange, forChat: conversationId)
            }
        }
    }
    
    private struct ConversationContext {
        var topicName: String?
        var conversationId: String?
        var taskId: String?
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
    private var handshakeCompletedHandler: ((ContextualActionMessage) -> Void)?
    
    private let logger = Logger(forCategory: "Chatterbox", level: .Info)
    
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
            case .failure:
                self?.logger.logError("getSession failed!")
            }
            completion(result.error)
        }
    }
    
    private func setupChatSubscription() {
        chatSubscription = apiManager.ambClient.subscribe(chatChannel) { [weak self] (subscription, message) in
            self?.logger.logDebug(message)
            
            if let messageHandler = self?.messageHandler {
                messageHandler(message)
            } else {
                self?.logger.logError("No handler set in Chatterbox onMessage!")
            }
        }
    }
    
    private func performChatHandshake(_ completion: @escaping (ContextualActionMessage) -> Void) {
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
                logger.logInfo("Handshake START message received")
                startUserSession(withInitEvent: initEvent)
            } else if initEvent.data.actionMessage.loginStage == MessageConstants.loginFinish.rawValue {
                logger.logInfo("Handshake FINISH message received: conversationID=\(conversationContext.conversationId ?? "nil")")
                
                conversationContext.conversationId = initEvent.data.conversationId
                
                // handshake done, setup handler for the topic selection
                messageHandler = self.topicSelectionHandler
            }
        }
    }
    
    private func topicSelectionHandler(_ message: String) {
        let choices: CBControlData = CBDataFactory.controlFromJSON(message)
        
        if choices.controlType == .contextualActionMessage {
            if let topicChoices = choices as? ContextualActionMessage, let completion = handshakeCompletedHandler {
                completion(topicChoices)
            } else {
                logger.logFatal("Could not call user session completion handler: invalid message or no handler provided")
            }
        }
    }
    
    private func startUserSession(withInitEvent initEvent: InitMessage) {
        let initUserEvent = createUserSessionInitMessage(fromInitEvent: initEvent)
        apiManager.ambClient.sendMessage(initUserEvent, toChannel: chatChannel, encoder: CBData.jsonEncoder)
    }
    
    private func createUserSessionInitMessage(fromInitEvent initEvent: InitMessage) -> InitMessage {
        var initUserEvent = initEvent
        
        initUserEvent.data.direction = .fromClient
        initUserEvent.data.sendTime = Date()
        initUserEvent.data.actionMessage.loginStage = MessageConstants.loginUserSession.rawValue
        initUserEvent.data.actionMessage.userId = user?.id
        initUserEvent.data.actionMessage.contextHandshake.consumerAccountId = user?.consumerAccountId
        initUserEvent.data.actionMessage.contextHandshake.vendorId = vendor?.vendorId
        initUserEvent.data.actionMessage.contextHandshake.deviceId = deviceIdentifier()
        
        if let request = initUserEvent.data.actionMessage.contextHandshake.serverContextRequest {
            initUserEvent.data.actionMessage.contextHandshake.serverContextResponse = serverContextResponse(fromRequest: request)
        }
        return initUserEvent
    }
    
    // MARK: User Topic Methods
    
    private func startTopicHandler(_ message: String) {
        Logger.default.logDebug("startTopicHandler received: \(message)")
        
        let picker: CBControlData = CBDataFactory.controlFromJSON(message)
        
        if picker.controlType == .topicPicker {
            if let topicPicker = picker as? UserTopicPickerMessage {
                if topicPicker.data.direction == .fromServer {
                    conversationContext.taskId = topicPicker.data.taskId
                    
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
        Logger.default.logDebug("startUserTopicHandshake received: \(message)")
        
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
        Logger.default.logDebug("userTopicMessage received: \(message)")
        
        if handleEventMessage(message) != true {
            handleControlMessage(message)
        }
    }
    
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
    
    fileprivate func handleControlMessage(_ message: String) {
        let control = CBDataFactory.controlFromJSON(message)
        
        switch control.controlType {
        case .boolean:
            handleBooleanControl(control)
        case .input:
            handleInputControl(control)
        case .picker:
            handlePickerControl(control)
        case .multiSelect:
            handleMultiSelectControl(control)
        case .text:
            handleTextControl(control)
        default:
            handleUnknownControl(control)
        }
    }
    
    fileprivate func handleBooleanControl(_ control: CBControlData) {
        if let booleanControl = control as? BooleanControlMessage, let conversationId = booleanControl.data.conversationId {
            var messageExchange = MessageExchange(withMessage: booleanControl)
            messageExchange.isComplete = false
            
            chatStore.storeControlData(booleanControl, expectResponse: true, forConversation: conversationId, fromChat: self)
            chatDataListener?.chatterbox(self, didReceiveBooleanData: booleanControl, forChat: chatId)
        }
    }
    
    fileprivate func handleInputControl(_ control: CBControlData) {
        if let inputControl = control as? InputControlMessage, let conversationId = inputControl.data.conversationId {
            chatStore.storeControlData(inputControl, expectResponse: true, forConversation: conversationId, fromChat: self)
            chatDataListener?.chatterbox(self, didReceiveInputData: inputControl, forChat: chatId)
        }
    }
    
    fileprivate func handlePickerControl(_ control: CBControlData) {
        if let pickerControl = control as? PickerControlMessage, let conversationId = pickerControl.data.conversationId {
            chatStore.storeControlData(pickerControl, expectResponse: true, forConversation: conversationId, fromChat: self)
            chatDataListener?.chatterbox(self, didReceivePickerData: pickerControl, forChat: chatId)
        }
    }
    
    fileprivate func handleMultiSelectControl(_ control: CBControlData) {
        if let multiSelectControl = control as? MultiSelectControlMessage, let conversationId = multiSelectControl.data.conversationId {
            chatStore.storeControlData(multiSelectControl, expectResponse: true, forConversation: conversationId, fromChat: self)
            chatDataListener?.chatterbox(self, didReceiveMultiSelectData: multiSelectControl, forChat: chatId)
        }
    }
    
    fileprivate func handleTextControl(_ control: CBControlData) {
        if let textControl = control as? OutputTextMessage, let conversationId = textControl.data.conversationId {
            chatStore.storeControlData(textControl, expectResponse: false, forConversation: conversationId, fromChat: self)
            chatDataListener?.chatterbox(self, didReceiveTextData: textControl, forChat: chatId)
        }
    }
    
    fileprivate func handleUnknownControl(_ control: CBControlData) {
        logger.logInfo("Ignoring unrecognized control type \(control.controlType)")
    }
    
    fileprivate func handleTopicFinishedAction(_ action: CBActionMessageData) {
        if let topicFinishedMessage = action as? TopicFinishedMessage {
            chatEventListener?.chatterbox(self, didFinishTopic: topicFinishedMessage, forChat: chatId)
        }
    }
    
    // MARK: cleanup
    
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

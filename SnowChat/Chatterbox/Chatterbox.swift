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
//         'init(instance: Instance, dataListener: ChatDataListener?, eventListener: ChatEventListener?)'
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
    case illegalState(details: String)
    case unknown(details: String)
}

class Chatterbox {
    let id = ChatUtil.uuidString()
    
    var user: ChatUser? {
        return session?.user
    }
    var vendor: ChatVendor?
    
    // AnyObject as type is a bummer, but Swift bug requires is https://bugs.swift.org/browse/SR-55
    // - workaround is to make notification wrappers to hide the casting...
    private(set) var chatDataListeners = ListenerList<AnyObject>()
    private(set) var chatEventListeners = ListenerList<AnyObject>()
    private(set) var chatAuthListeners = ListenerList<AnyObject>()
    
    internal func notifyDataListeners(_ closure: (ChatDataListener) -> Void) {
        chatDataListeners.forEach(withType: ChatDataListener.self) { listener in
            closure(listener)
        }
    }

    internal func notifyEventListeners(_ closure: (ChatEventListener) -> Void) {
        chatEventListeners.forEach(withType: ChatEventListener.self) { listener in
            closure(listener)
        }
    }

    internal func notifyAuthListeners(_ closure: (ChatAuthListener) -> Void) {
        chatAuthListeners.forEach(withType: ChatAuthListener.self) { listener in
            closure(listener)
        }
    }
    
    internal var conversationContext = ConversationContext()
    internal var contextualActions: ContextualActionMessage?
    
    internal let chatStore = ChatDataStore(storeId: "ChatterboxDataStore")
    
    var session: ChatSession? {
        didSet {
            updateSettings()
        }
    }
    
    internal let chatId = ChatUtil.uuidString()
    internal var chatChannel: String {
        return "/cs/messages/\(chatId)"
    }
    internal var chatSubscription: AMBSubscription?
    
    internal var supportQueueSubscription: AMBSubscription?
    internal var supportQueueInfo: SupportQueue?
    
    internal let serverInstance: ServerInstance
    
    private(set) internal lazy var apiManager: APIManager = {
        return APIManager(instance: serverInstance, transportListener: self)
    }()

    internal enum ChatState {
        case uninitialized
        case topicSelection
        case userConversation
        case waitingForAgent
        case agentConversation
    }
    
    internal var state = ChatState.uninitialized {
        didSet {
            logger.logDebug("Chatterbox State set to: \(state) from \(oldValue)")
        }
    }
    
    internal var messageHandler: ((String) -> Void)?
    internal var handshakeCompletedHandler: ((ContextualActionMessage?) -> Void)?
    
    internal let logger = Logger.logger(for: "Chatterbox")
    
    internal var userContextData: Codable?
    internal let appContextManager = AppContextManager()
    
    internal func updateSettings() {
        if let theme = session?.settings?.brandingSettings?.theme {
            theme.instanceURL = serverInstance.instanceURL
        }
        
        if let settings = session?.settings?.virtualAgentSettings,
            let avatarPath = settings.avatar,
            let theme = session?.settings?.brandingSettings?.theme {
            theme.updateAvatar(path: avatarPath)
        }
    }
    
    // MARK: - Methods
    
    init(instance: ServerInstance) {
        self.serverInstance = instance
    }
    
    internal func publishMessage<T>(_ message: T) where T: Encodable {
        logger.logInfo("Chatterbox publishing message: \(message)")
        apiManager.sendMessage(message, toChannel: chatChannel, encoder: ChatUtil.jsonEncoder)
    }

    internal func lastPendingControlMessage(forConversation conversationId: String) -> ControlData? {
        return chatStore.lastPendingMessage(forConversation: conversationId) as? ControlData
    }
    
    internal func cancelConversation() {
        switch state {
        case .userConversation:
            cancelUserConversation()
        case .waitingForAgent, .agentConversation:
            endAgentConversation()
        default:
            break
        }
    }
    // MARK: - Incoming messages (Controls from service)
    
    internal func processEventMessage(_ message: String) -> Bool {
        let action = ChatDataFactory.actionFromJSON(message)
        
        guard action.eventType != .unknown else { return false }
        
        switch action.eventType {
        case .finishedUserTopic:
            guard let topicFinished = action as? TopicFinishedMessage else { return false }
            didReceiveTopicFinishedAction(topicFinished)
        case .supportQueueSubscribe:
            if let subscribeMessage = action as? SubscribeToSupportQueueMessage {
                didReceiveSubscribeToSupportAction(subscribeMessage)
            }
        default:
            logger.logInfo("Unhandled event message: \(action.eventType)")
        }
        return true
    }
    
    internal func processIncomingControlMessage(_ control: ControlData, forConversation conversationId: String) {
        chatStore.storeControlData(control, forConversation: conversationId, fromChat: self)
        
        notifyDataListeners { listener in
            listener.chatterbox(self, didReceiveControlMessage: control, forChat: chatId)
        }
    }
    
    fileprivate func processResponseControlMessage(_ control: ControlData, forConversation conversationId: String) {
        if let lastExchange = chatStore.conversation(forId: conversationId)?.messageExchanges().last, !lastExchange.isComplete {
            if let updatedExchange = chatStore.storeResponseData(control, forConversation: conversationId) {
                notifyDataListeners { listener in
                    listener.chatterbox(self, didCompleteMessageExchange: updatedExchange, forChat: conversationId)
                }
            }
        } else {
            // our own reply message from an agent chat
            processIncomingControlMessage(control, forConversation: conversationId)
        }
    }
    
    internal func processControlMessage(_ control: ControlData) {
        guard control.controlType != .unknown else {
            logger.logInfo("Unknown control type: \(control)")
            return
        }
        
        switch control.direction {
        case .fromClient:
            if let conversationId = conversationContext.conversationId {
                processResponseControlMessage(control, forConversation: conversationId)
            }
        
        case .fromServer:
            updateContextIfNeeded(control)
            
            if state == .waitingForAgent {
                if let isAgent = control.isAgent, isAgent == true {
                    // this signals the start of the agent conversation
                    state = .agentConversation
                    agentTopicStarted(withMessage: control)
                }
            }
            
            if control.controlType == .contextualAction, let contextualActionControl = control as? ContextualActionMessage {
                updateContextualActions(contextualActionControl)
                return
            }
            
            if let conversationId = conversationContext.conversationId {
                processIncomingControlMessage(control, forConversation: conversationId)
            }
        }
    }
    
    fileprivate func updateContextualActions(_ newContextualActions: ContextualActionMessage) {
        logger.logInfo("Updating ContextualActions: \(newContextualActions.data.richControl?.uiMetadata?.inputControls ?? [])")
        contextualActions = newContextualActions
    }
    
    fileprivate func updateContextIfNeeded(_ control: ControlData) {
        // keep our taskId and conversationID up to date with incoming messages
        
        if let taskId = control.taskId {
            conversationContext.taskId = taskId
        }
        
        if let conversationId = control.conversationId,
           conversationId != conversationContext.systemConversationId {

            conversationContext.conversationId = conversationId
        }
    }
    
    internal func didReceiveSystemError(_ message: String) {
        switch state {
        case .userConversation:
            transferToLiveAgent()
        case .waitingForAgent, .agentConversation, .topicSelection:
            // signal an end of conversation so the user can try a new conversation
            guard let sessionId = self.conversationContext.sessionId,
                let conversationId = self.conversationContext.conversationId else { return }
            self.didReceiveTopicFinishedAction(TopicFinishedMessage(withSessionId: sessionId, withConversationId: conversationId))
        default:
            logger.logFatal("*** System Error encountered outside of User Conversation! ***")
        }
    }
    
    internal func didReceiveTopicFinishedAction(_ action: TopicFinishedMessage) {
        cancelPendingExchangeIfNeeded()
        
        conversationContext.conversationId = nil
        
        saveDataToPersistence()
        
        let topicInfo = nullTopicInfo
        notifyEventListeners { listener in
            listener.chatterbox(self, didFinishTopic: topicInfo, forChat: chatId)
        }
    }

    internal func didReceiveSubscribeToSupportAction(_ subscribeMessage: SubscribeToSupportQueueMessage) {
        supportQueueInfo = subscribeMessage.data.actionMessage.supportQueue
        subscribeToSupportQueue(subscribeMessage)
    }
    
    internal func cancelPendingExchangeIfNeeded() {
        if let conversationId = conversationContext.conversationId,
            let lastExchange = chatStore.conversation(forId: conversationId)?.messageExchanges().last, !lastExchange.isComplete {
            
            chatStore.cancelPendingExchange(forConversation: conversationId)
            notifyDataListeners { listener in
                listener.chatterbox(self, didCompleteMessageExchange: lastExchange, forChat: conversationId)
            }
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
        case .dateTime:
            updateDateTimeControl(control)
        case .date, .time:
            updateDateOrTimeControl(control)
        case .agentText:
            // NOTE: only used for live agent mode
            updateTextControl(control)
        case .fileUpload:
            updateFileUploadControl(control)
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
        publishMessage(message)
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
    
    fileprivate func updateDateTimeControl(_ control: ControlData) {
        if var dateTimeControl = control as? DateTimePickerControlMessage, let conversationId = dateTimeControl.data.conversationId {
            dateTimeControl.data = updateRichControlData(dateTimeControl.data)
            publishControlUpdate(dateTimeControl, forConversation: conversationId)
        }
    }
    
    fileprivate func updateDateOrTimeControl(_ control: ControlData) {
        if var dateTimeControl = control as? DateOrTimePickerControlMessage, let conversationId = dateTimeControl.data.conversationId {
            dateTimeControl.data = updateRichControlData(dateTimeControl.data)
            publishControlUpdate(dateTimeControl, forConversation: conversationId)
        }
    }
    
    fileprivate func updateTextControl(_ control: ControlData) {
        if let textControl = control as? AgentTextControlMessage, let conversationId = textControl.conversationId {
            publishControlUpdate(textControl, forConversation: conversationId)
        }
    }
    
    fileprivate func updateFileUploadControl(_ control: ControlData) {
        if var fileUploadControl = control as? FileUploadControlMessage, let conversationId = fileUploadControl.data.conversationId {
            fileUploadControl.data = updateRichControlData(fileUploadControl.data)
            publishControlUpdate(fileUploadControl, forConversation: conversationId)
        }
    }
    
    // MARK: Chatbot and Agent shared functionality
    
    internal func showTopic(completion: @escaping () -> Void) {
        guard let sessionId = session?.id,
            let conversationId = conversationContext.systemConversationId,
            let uiMetadata = contextualActions?.data.richControl?.uiMetadata else {
                logger.logError("Could not perform showTopic handshake: no conversationID or contextualActions")
                completion()
                return
        }
        
        var startTopic = StartTopicMessage(withSessionId: sessionId, withConversationId: conversationId, uiMetadata: uiMetadata)
        startTopic.data.richControl?.value = "showTopic"
        startTopic.data.direction = .fromClient
        
        installShowTopicHandler {
            completion()
        }
        
        publishMessage(startTopic)
    }
    
    internal func installShowTopicHandler(completion:  @escaping () -> Void) {
        let previousHandler = messageHandler
        
        messageHandler = { [weak self] message in
            guard let strongSelf = self else { return }
            
            // expect a topicPicker back, resend it with the FIRST option picked, and get back a ShowTopic confirmation
            // NOTE: we always resume the LAST topic, which is the first in the picker-list. Eventually we
            //       may show a menu of choices and let the user pick which topic to resume...
            
            let controlMessage = ChatDataFactory.controlFromJSON(message)
            
            if let pickerMessage = controlMessage as? PickerControlMessage {
                guard pickerMessage.direction == .fromServer,
                    let count = pickerMessage.data.richControl?.uiMetadata?.options.count, count > 0 else { return }
                
                let topicToResume = pickerMessage.data.richControl?.uiMetadata?.options[0].value
                var responseMessage = pickerMessage
                responseMessage.data.richControl?.value = topicToResume
                responseMessage.data.sendTime = Date()
                responseMessage.data.direction = .fromClient
                strongSelf.publishMessage(responseMessage)
                
            } else {
                let actionMessage = ChatDataFactory.actionFromJSON(message)
                
                guard actionMessage.direction == .fromServer,
                    let showTopicMessage = actionMessage as? ShowTopicMessage else { return }
                
                var response = showTopicMessage
                response.data.direction = .fromClient
                response.data.sendTime = Date()
                response.data.actionMessage.ready = true
                strongSelf.publishMessage(response)
                
                let sessionId = showTopicMessage.data.sessionId
                let topicId = showTopicMessage.data.actionMessage.topicId
                let taskId = showTopicMessage.data.taskId
                
                strongSelf.conversationContext.conversationId = topicId
                strongSelf.conversationContext.sessionId = sessionId
                strongSelf.conversationContext.taskId = taskId
                
                strongSelf.logger.logDebug("Topic resumed: topicId=\(topicId)")
                strongSelf.messageHandler = previousHandler
                
                completion()
            }
        }
    }
    
    // MARK: - Conversation Access
    
    func currentConversationHasControlData(forId messageId: String) -> Bool {
        guard let conversationId = conversationContext.conversationId else { return false }
        
        let message = chatStore.conversation(forId: conversationId)?.messageExchanges().first(where: { (exchange) -> Bool in
            exchange.message.messageId == messageId
        })
        
        return message != nil
    }
    
    func conversation(forId conversationId: String) -> Conversation? {
        return chatStore.conversation(forId: conversationId)
    }
    
    internal func clearMessageHandlers() {
        messageHandler = nil
        handshakeCompletedHandler = nil
    }
    
    // MARK: Structures and Types
    
    internal struct ConversationContext {
        var topicName: String?
        var sessionId: String?
        
        var taskId: String?
        
        var conversationId: String?
        var systemConversationId: String?
    }
}

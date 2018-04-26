import Foundation

public typealias AMBMessageDictionary = [String : Any]
public typealias AMBMessageDataExtention = [String : Any]
public typealias AMBMessageHandler = (AMBResult<AMBMessage>, AMBSubscription) -> Void
public typealias AMBPublishMessageHandler = (AMBResult<AMBMessage>) -> Void

//
// MARK: - AMBResult
//

public enum AMBResult<Value> {
    case success(Value)
    case failure(AMBError)
        public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    public var error: AMBError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

//
// MARK: - AMBGlideStatus
//

public enum AMBGlideSessionStatus: String {
    case loggedIn = "session.logged.in"
    case loggedOut = "session.logged.out"
    case invalidated = "session.invalidated"
}

public struct AMBGlideStatus: Equatable {
    public let ambActive: Bool
    public let sessionStatus: AMBGlideSessionStatus?
    
    public static func == (lhs: AMBGlideStatus, rhs: AMBGlideStatus) -> Bool {
        return lhs.ambActive == rhs.ambActive &&
            lhs.sessionStatus == rhs.sessionStatus
    }
    
}

//
// MARK: - AMBClientDelegate
//

public protocol AMBClientDelegate: AnyObject {
    func ambClientDidConnect(_ client: AMBClient)
    func ambClientDidDisconnect(_ client: AMBClient)
    func ambClient(_ client: AMBClient, didSubscribeToChannel channel: String)
    func ambClient(_ client: AMBClient, didUnsubscribeFromChannel channel: String)
    func ambClient(_ client: AMBClient, didReceiveMessage: AMBMessage, fromChannel channel: String)
    func ambClient(_ client: AMBClient, didChangeClientStatus status: AMBClientStatus)
    func ambClient(_ client: AMBClient, didReceiveGlideStatus status: AMBGlideStatus)
    func ambClient(_ client: AMBClient, didFailWithError error: AMBError)
}

//
// MARK: - AMBClientStatus
//

public enum AMBClientStatus {
    case disconnected
    case handshake
    case connected
    case retrying
    case maximumRetriesReached
}

enum AMBChannel: String {
    case handshake = "/meta/handshake"
    case connect = "/meta/connect"
    case disconnect = "/meta/disconnect"
    case subscribe = "/meta/subscribe"
    case unsubscribe = "/meta/unsubscribe"
    
    var name: String {
        return self.rawValue
    }
}

//
// MARK: - AMBClient
//

public class AMBClient {
    let bayeuxSupportedConnections = ["long-polling"]
    let bayeuxProtocolVersion = "1.0"
    let bayeuxMinimumSupportedProtocolVersion = "1.0beta"
    
    enum ReconnectAdviceField: String {
        case handshake
        case retry
        
        var name: String {
            return rawValue
        }
    }
    
    weak public var delegate: AMBClientDelegate?
    let httpClient: SNOWHTTPSessionClientProtocol
    
    public var clientId: String?
    
    public var maximumRetryAttempts = 5
    
    struct PostedMessageHandler {
        let timestamp: Date
        var handler: AMBPublishMessageHandler
        
        init(handler: @escaping AMBPublishMessageHandler) {
            self.timestamp = Date()
            self.handler = handler
        }
    }
    // [messageId: PostedMessageHandler]
    private var postedMessageHandlers = [String : PostedMessageHandler]()
    
    private var subscriptionsByChannel = [String : [AMBSubscriptionWeakWrapper]]()
    private var subscribedChannels = Set<String>()
    private var queuedSubscriptionChannels = Set<String>()
    private var longPollingInterval: TimeInterval = 0.0
    private var longPollingTimeout: TimeInterval = 0.0
    private let retryInterval: TimeInterval = 10.0
    private var retryAttempt = 0
    private var reopenChannelsAfterSuccessfulConnectMessages = true
    private var dataTasks = [URLSessionDataTask]()
    private var unsubscribeLock = false
    
    private var scheduledConnectTask: DispatchWorkItem?
    private var connectDataTask: URLSessionDataTask?
    private var connectDataTaskTime: Date?
    private var messageId = 0
    
    public var clientStatus = AMBClientStatus.disconnected {
        didSet {
            if oldValue != self.clientStatus {
                log("client state \(clientStatus)")
                delegate?.ambClient(self, didChangeClientStatus: clientStatus)
                switch self.clientStatus {
                case .retrying, .handshake:
                    retryAttempt = 0
                case .connected:
                    subscribeQueuedChannels()
                    delegate?.ambClientDidConnect(self)
                case .disconnected:
                    cancelAllDataTasks()
                    delegate?.ambClientDidDisconnect(self)
                case .maximumRetriesReached:
                    delegate?.ambClient(self,
                                      didFailWithError: AMBError.connectFailed(description: "Maximum connect retry attempts have been reached"))
                }
            }
        }
    }
    
    public var glideStatus: AMBGlideStatus = AMBGlideStatus(ambActive: false, sessionStatus: nil) {
        didSet {
            delegate?.ambClient(self, didReceiveGlideStatus: glideStatus)
        }
    }
    
    public var isPaused: Bool = false {
        didSet {
            if isPaused != oldValue {
                if isPaused {
                    // Looks like connect task cancellation often leaves server in bad state,
                    // so instead we keep all tasks alive until they die on timeout or server explicitely kills them (alex a, 02-27-18)
                    // TODO: Keep testing this!
//                    cancelAllDataTasks()
                } else {
                    let currentTime = Date()
                    if let connectDataTaskTime = self.connectDataTaskTime {
                        let timeDiff = Double(Int(currentTime.timeIntervalSince1970 - connectDataTaskTime.timeIntervalSince1970))
                        if longPollingTimeout > 0 && timeDiff > longPollingTimeout / 1000 {
                            self.clientStatus = .disconnected
                            connect()
                            return
                        }
                    }
                    startConnectRequest()
                }
            }
        }
    }
    
    public init(httpClient: SNOWHTTPSessionClientProtocol) {
        self.httpClient = httpClient
    }

    // TODO: Use Logger instead?
    func log(_ logString: String) {
        #if DEBUG
            NSLog("AMB Client: \(logString)")
        #endif
    }
    
    // MARK: - Public methods
    
    public func connect() {
        sendBayeuxHandshakeMessage()
    }
    
    public func publishMessage(_ message: AMBMessageDictionary,
                               toChannel channel: String,
                               withExtension ext: AMBMessageDataExtention? = nil,
                               completion handler: @escaping AMBPublishMessageHandler) {
        sendBayeuxPublishMessage(message, toChannel: channel, withExtension: ext, completion: handler)
    }
    
    public func subscribe(channel: String, messageHandler: @escaping AMBMessageHandler) -> AMBSubscription {
        cleanupSubscriptions()
        
        let subscription = AMBSubscription(channel: channel, client: self, messageHandler: messageHandler)
        let newWrapper = AMBSubscriptionWeakWrapper(subscription)
        if subscriptionsByChannel[channel] == nil {
            subscriptionsByChannel[channel] = [newWrapper]
            if self.clientStatus == .connected {
                sendBayeuxSubscribeMessage(channel: channel)
            } else {
                queuedSubscriptionChannels.insert(channel)
            }
        } else {
            newWrapper.subscription?.subscribed = subscribedChannels.contains(channel)
            subscriptionsByChannel[channel]?.append(newWrapper)
        }
        
        return subscription
    }
    
    public func resubscribe(channel: String) {
        if subscribedChannels.contains(channel) {
            return
        }
        queuedSubscriptionChannels.insert(channel)
        sendBayeuxSubscribeMessage(channel: channel)
    }
    
    public func unsubscribe(subscription: AMBSubscription) {
        // unsubscribe() may be called from AMBSubscription.deinit() and when we update subscriptions inside
        // this method.
        // It may cause race condition which we want to avoid by using this lock.
        guard !self.unsubscribeLock else { return }
        self.unsubscribeLock = true
        
        cleanupSubscriptions()

        guard var subscriptions = subscriptionsByChannel[subscription.channel],
                  !subscriptions.isEmpty  else {
            return
        }
        
        for (index, subscriptionWrapper) in subscriptions.enumerated() {
            if let curSubscription = subscriptionWrapper.subscription {
                if curSubscription.uuid == subscription.uuid {
                    subscription.subscribed = false
                    subscriptions[index].subscription = subscription
                }
            }
        }
        
        subscriptions = subscriptions
            .filter({ (subscriptionWrapper) in
                    subscriptionWrapper.subscription?.subscribed ?? false
            })

        if subscriptions.isEmpty {
            sendBayeuxUnsubscribeMessage(channel: subscription.channel)
        }
        
        self.unsubscribeLock = false
    }
    
    public func tearDown() {
        cancelAllDataTasks()
        self.postedMessageHandlers.removeAll()
        self.clientStatus = .disconnected
    }
}

//
// MARK: - Private methods
//

private extension AMBClient {
    
    func startConnectRequest(after interval: TimeInterval = 0.0) {
        guard !isPaused else {
            log("Client is paused. Connect request is skipped")
            return
        }
        
        guard self.clientStatus != .disconnected else {
            log("Client is disconnected. Connect request is skipped. Handshake must be completed first")
            return
        }
        
        if let connectDataTask = self.connectDataTask {
            if connectDataTask.state == URLSessionDataTask.State.running {
                log("data task is still in flight, new connect request was not created")
                if self.clientStatus == .retrying {
                    self.clientStatus = .connected
                }
                return
            }
        }
        
        self.scheduledConnectTask = DispatchWorkItem { [weak self] in
            self?.sendBayeuxConnectMessage()
        }
        
        if let scheduledConnectTask = self.scheduledConnectTask {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + interval,
                                          execute: scheduledConnectTask)
        }
    }
    
    func cancelAllDataTasks() {
        self.scheduledConnectTask?.cancel()
        self.scheduledConnectTask = nil
        dataTasks.forEach({ $0.cancel() })
        cleanupCompletedDataTasks()
    }
    
    func cleanupCompletedDataTasks() {
        dataTasks = dataTasks.filter({ $0.state != URLSessionTask.State.completed })
    }
    
    func cleanupSubscriptions() {
        for (channel, subscriptions) in self.subscriptionsByChannel {
            self.subscriptionsByChannel[channel] = subscriptions.filter({ $0.subscription != nil })
        }
    }
    
    // MARK: - AMB/Bayeux message handlers
    
    func parseResponseObject(_ responseObject: Any?) -> AMBResult<[AMBMessage]> {
        var parsedMessages = [AMBMessage]()
        
        guard responseObject as? [AMBMessageDictionary] != nil else {
            let error = AMBError.messageParserError(description: "messages are not packaged in array")
            delegate?.ambClient(self, didFailWithError: error)
            return AMBResult.failure(error)
        }
        
        for rawMessage in (responseObject as! [AnyObject]) {
            guard rawMessage as? AMBMessageDictionary != nil else {
                let error = AMBError.messageParserError(description: "message is not Dictionary")
                delegate?.ambClient(self, didFailWithError: error)
                return AMBResult.failure(error)
            }
            do {
                if let ambMessage = try AMBMessage(rawMessage: rawMessage) {
                   handleAMBMessage(ambMessage)
                   parsedMessages.append(ambMessage)
                }
            } catch {
                let error = AMBError.messageParserError(description: "message is not well formatted")
                delegate?.ambClient(self, didFailWithError: error)
                return AMBResult.failure(error)
            }
        }
        return AMBResult.success(parsedMessages)
    }
    
    private func handleAMBMessage(_ ambMessage: AMBMessage) {
        let channel = ambMessage.channel
        
        switch channel {
        case AMBChannel.handshake.name:
            handleHandshakeMessage(ambMessage)
            
        case AMBChannel.connect.name:
            handleConnectMessage(ambMessage)
            
        case AMBChannel.disconnect.name:
            handleDisconnectMessage(ambMessage)
            
        case AMBChannel.subscribe.name:
            handleSubscribeMessage(ambMessage)
            
        case AMBChannel.unsubscribe.name:
            handleUnsubscribeMessage(ambMessage)
            
        default:
            handleChannelMessage(ambMessage, channel: channel)
        }
    }
    
    private func notifyChannelSubscribersWithMessage(_ message: AMBMessage) {
        if let subscriptionWrappers = subscriptionsByChannel[message.channel] {
            subscriptionWrappers.forEach({ subscriptionWrapper in
                if let subscription = subscriptionWrapper.subscription {
                    subscription.messageHandler(AMBResult.success(message), subscription)
                }
            })
        } else {
            // no handler for this channel, using delegate
            delegate?.ambClient(self, didReceiveMessage: message, fromChannel: message.channel)
        }
    }
    
    func handleChannelMessage(_ ambMessage: AMBMessage, channel: String) {
        if self.isPaused {
            log("incoming message when client is paused. Skipping.")
            return
        }
        
        if !subscribedChannels.contains(channel) {
            // message was received for a channel client is not subscribed to
            delegate?.ambClient(self,
                              didFailWithError: AMBError.unhandledMessageReceived(channel: channel))
        }
    }
    
    func handleHandshakeMessage(_ ambMessage: AMBMessage) {
        if ambMessage.successful {
            retryAttempt = 0
            self.clientId = ambMessage.clientId
            self.clientStatus = .connected
        } else {
            delegate?.ambClient(self,
                              didFailWithError: AMBError.handshakeFailed(description: "AMB could not handshake with error:\(ambMessage.errorString ?? "")"))
        }
        self.reopenChannelsAfterSuccessfulConnectMessages = true
        startConnectRequest()
    }

    func subscribeQueuedChannels() {
        queuedSubscriptionChannels.forEach({ sendBayeuxSubscribeMessage(channel: $0) })
        queuedSubscriptionChannels.removeAll()
    }
    
    func reopenSubscriptions() {
        let oldSubscribedChannels = subscribedChannels.union(queuedSubscriptionChannels)
        subscribedChannels.removeAll()
        queuedSubscriptionChannels.removeAll()
        
        oldSubscribedChannels.forEach({ (channel) in
            resubscribe(channel: channel)
        })
    }
    
    func handleConnectMessage(_ ambMessage: AMBMessage) {
        
        func parseGlideSessionStatus(from ext: [String : Any]) {
            let sessionStatusString = ext["glide.session.status"] as? String
            let sessionStatus = sessionStatusString.flatMap { AMBGlideSessionStatus(rawValue: $0) }
            
            let ambActive = ext["glide.amb.active"] as? Bool ?? false
            
            glideStatus = AMBGlideStatus(ambActive: ambActive, sessionStatus: sessionStatus)
        }
        
        if  let advice = ambMessage.advice,
            let reconnectAdvice = advice["reconnect"] as? String {
            if reconnectAdvice == "handshake" {
                self.clientStatus = .disconnected
                sendBayeuxHandshakeMessage()
                return
            }
        }
        
        if ambMessage.successful {
            scheduledConnectTask = nil
    
            if let ext = ambMessage.ext {
                parseGlideSessionStatus(from: ext)
            }
            
            if self.reopenChannelsAfterSuccessfulConnectMessages {
                self.reopenChannelsAfterSuccessfulConnectMessages = false
                reopenSubscriptions()
            }
            
            self.clientStatus = .connected
            
            if  let advice = ambMessage.advice {
                let interval = advice["interval"] as? TimeInterval ?? 0.0
                if let timeout = advice["timeout"] as? TimeInterval {
                    self.longPollingTimeout = timeout
                }
                
                if interval > 0 {
                    log("Delaying connection by: \(interval)")
                    startConnectRequest(after: interval)
                    return
                }
            }
            startConnectRequest()
        } else {
            if self.clientStatus == .retrying {
                retryAttempt += 1
                if retryAttempt > maximumRetryAttempts {
                    self.clientStatus = .maximumRetriesReached
                } else {
                    // connect will be scheduled in 10.0f.
                    startConnectRequest()
                }
            } else {
                delegate?.ambClient(self, didFailWithError: AMBError.connectFailed(description: "success flag was set to false by server"))
            }
        }
    }
    
    func handleDisconnectMessage(_ ambMessage: AMBMessage) {
        if ambMessage.successful {
            cancelAllDataTasks()
            subscribedChannels.removeAll()
            subscriptionsByChannel.removeAll()
        } else {
            delegate?.ambClient(self, didFailWithError: AMBError.disconnectFailed)
        }
    }
    
    func handleSubscribeMessage(_ ambMessage: AMBMessage) {
        if ambMessage.successful {
            guard let channel = ambMessage.subscription else {
                return
            }
            subscribedChannels.insert(channel)
            if let subscriptions = subscriptionsByChannel[channel] {
                var updatedSubscriptions = [AMBSubscriptionWeakWrapper]()
                subscriptions.forEach({ (subscriptionWrapper) in
                    if let subscription = subscriptionWrapper.subscription {
                        subscription.subscribed = true
                        let updatedWrapper = AMBSubscriptionWeakWrapper(subscription)
                        updatedSubscriptions.append(updatedWrapper)
                        // letting subscriber know that subscription went through
                        subscription.messageHandler(AMBResult.success(ambMessage), subscription)
                    }
                })
                subscriptionsByChannel[channel] = updatedSubscriptions
                queuedSubscriptionChannels.remove(channel)
                delegate?.ambClient(self, didSubscribeToChannel: channel)
            }
        } else {
            delegate?.ambClient(self, didFailWithError: AMBError.disconnectFailed)
        }
    }
    
    func handleUnsubscribeMessage(_ ambMessage: AMBMessage) {
        if ambMessage.successful {
            subscribedChannels.remove(ambMessage.channel)
            cleanupSubscriptions()
            delegate?.ambClient(self, didUnsubscribeFromChannel: ambMessage.subscription ?? "")
        } else {
            delegate?.ambClient(self, didFailWithError: AMBError.disconnectFailed)
        }
    }

    // MARK: - Bayeux messages
    
    func sendBayeuxHandshakeMessage() {
        cancelAllDataTasks()
        connectDataTaskTime = nil
        self.postedMessageHandlers.removeAll()
        
        let message = [
            "channel" : AMBChannel.handshake.name,
            "version" : bayeuxProtocolVersion,
            "minimumVersion" : bayeuxMinimumSupportedProtocolVersion,
            "supportedConnections" : bayeuxSupportedConnections
        ] as [String : Any]
    
        self.clientStatus = .handshake
        postBayeuxMessage(message)
    }
    
    func sendBayeuxConnectMessage() {
        guard let clientId = self.clientId else {
            delegate?.ambClient(self,
                              didFailWithError: AMBError.connectFailed(description: "Connect message can't be send because clientId is not received yet"))
            return
        }
        
        let message = [
            "channel" : AMBChannel.connect.name,
            "clientId" : clientId,
            "supportedConnections" : bayeuxSupportedConnections
        ] as [String : Any]
        
        var timeout: TimeInterval = self.longPollingInterval
        if self.clientStatus == .retrying {
            timeout = 10.0
        }
        
        postBayeuxMessage(message, timeout: timeout)
    }
    
    func sendBayeuxSubscribeMessage(channel: String) {
        guard let clientId = self.clientId else {
            delegate?.ambClient(self, didFailWithError: AMBError.subscribeFailed)
            return
        }
        
        let message = [
            "channel" : AMBChannel.subscribe.name,
            "clientId" : clientId,
            "subscription" : channel
        ]  as [String : Any]
        
        postBayeuxMessage(message)
    }
    
    func sendBayeuxUnsubscribeMessage(channel: String) {
        guard let clientId = self.clientId else {
            delegate?.ambClient(self, didFailWithError: AMBError.unsubscribeFailed)
            return
        }
        
        let message  = [
            "channel" : AMBChannel.unsubscribe.name,
            "clientId" : clientId,
            "subscription" : channel
        ] as [String : Any]
        
        postBayeuxMessage(message)
    }
    
    func sendBayeuxPublishMessage(_ message: AMBMessageDictionary,
                                  toChannel channel: String,
                                  withExtension ext: AMBMessageDataExtention? = nil,
                                  completion handler: AMBPublishMessageHandler? = nil) {
        
        guard clientStatus == .connected else {
            delegate?.ambClient(self,
                              didFailWithError: AMBError.publishFailed(description: "client not connected to server"))
            return
        }
        
        guard let clientId = self.clientId else {
            delegate?.ambClient(self,
                              didFailWithError: AMBError.publishFailed(description: "clientId was not set yet"))
            return
        }

        // Faye client was sending `id` as base64 encoded sequential number
        // however old AMB client was overriding `id` with uint32 value (alex a, 02-14-18)
//        sentMessageCount += 1
//        let messageId = Data(String(sentMessageCount).utf8).base64EncodedString()
        
        var bayeuxMessage = [
            "channel"  : channel,
            "clientId" : clientId,
            "data" : message
        ]  as [String : Any]
        
        if let ext = ext, !ext.isEmpty {
            bayeuxMessage["ext"] = ext
        }
        
        postBayeuxMessage(bayeuxMessage, completion: handler)
    }
    
    private func channelNameToPath(_ channel: String) -> String {
        var path = ""
        if channel.hasPrefix("/meta") {
            let parts = channel.split(separator: "/").map(String.init)
            guard let lastPart = parts.last else {
                return ""
            }
            switch channel {
            case AMBChannel.handshake.name:
                path = lastPart
            case AMBChannel.connect.name:
                path = lastPart
            default:
                path = ""
            }
        }
        return path
    }
    
    func invokeHandlers(forMessages messages: [AMBMessage]) {
        guard !self.isPaused else {
            return
        }
        
        messages.forEach({ (message) in
            notifyChannelSubscribersWithMessage(message)
            
            if let messageId = message.id,
               let postedMessageHandler = postedMessageHandlers[messageId] {
                postedMessageHandler.handler(AMBResult.success(message))
            }
        })
        
        self.postedMessageHandlers = postedMessageHandlers.filter {
            (Date().timeIntervalSince1970 - $1.timestamp.timeIntervalSince1970) < (longPollingTimeout / 1000 * 2)
        }
    }
    
    @discardableResult func postBayeuxMessage(_ message: [String : Any],
                                              timeout: TimeInterval = 0.0,
                                              completion handler: AMBPublishMessageHandler? = nil) -> URLSessionDataTask? {
        
        guard let channel = message["channel"] as? String else {
            delegate?.ambClient(self,
                              didFailWithError: AMBError.httpRequestFailed(description: "message is missing a channel field"))
            return nil
        }
        
        var myMessage = message
        
        myMessage["id"] = messageId
        messageId += 1

        let path = channelNameToPath(channel)
        let fullPath = String(format:"/amb/%@", path)
        if let handler = handler {
            self.postedMessageHandlers[String(messageId)] = PostedMessageHandler(handler: handler)
        }
        
        let task = httpClient.post(fullPath, jsonParameters: myMessage as Any, timeout: timeout,
            success: { [weak self] (responseObject: Any?) -> Void in
                guard let strongSelf = self else { return }
                let result = strongSelf.parseResponseObject(responseObject)
                if let messages = result.value {
                    strongSelf.invokeHandlers(forMessages: messages)
                }
            },
            failure: { [weak self] (error: Any?) -> Void in
                guard let strongSelf = self else { return }
                let httpError = error as! Error
                if let handler = handler {
                    handler(AMBResult.failure(AMBError.httpRequestFailed(description: httpError.localizedDescription)))
                }
                strongSelf.handleHTTPResponseError(message: myMessage, error: httpError)
        })

        if let task = task {
            if channel == AMBChannel.connect.name {
                connectDataTaskTime = Date()
                connectDataTask = task
            }
            dataTasks.append(task)
        }
        cleanupCompletedDataTasks()
        
        return task
    }
    
    func handleHTTPResponseError(message: AMBMessageDictionary, error: Error) {
        cleanupCompletedDataTasks()
        
        if self.isPaused {
            log("AMB Client. HTTP Error \(error.localizedDescription) received. Ignoring because client is paused")
            return
        }

        delegate?.ambClient(self,
                          didFailWithError: AMBError.httpRequestFailed(description: "request failed with error:\(error.localizedDescription)"))
        if self.clientStatus == .handshake {
            delegate?.ambClient(self,
                              didFailWithError: AMBError.handshakeFailed(description: "Handshake request failed"))
            return
        }
        if self.clientStatus == .connected {
            self.clientStatus = .retrying
        }
        startConnectRequest(after: retryInterval)
    }
    
}

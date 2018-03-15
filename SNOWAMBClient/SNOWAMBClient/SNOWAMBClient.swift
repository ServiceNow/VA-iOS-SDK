import Foundation

public typealias SNOWAMBMessageDictionary = [String : Any]
public typealias SNOWAMBMessageDataExtention = [String : Any]
public typealias SNOWAMBMessageHandler = (SNOWAMBResult<SNOWAMBMessage>, SNOWAMBSubscription) -> Void
public typealias SNOWAMBPublishMessageHandler = (SNOWAMBResult<[SNOWAMBMessage]>) -> Void

//
// SNOWAMBResult
//

public enum SNOWAMBResult<Value> {
    case success(Value)
    case failure(SNOWAMBError)
    
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    public var error: SNOWAMBError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

//
// SNOWAMBGlideStatus
//

public enum AMBGlideSessionStatus: String {
    case loggedIn = "session.logged.in"
    case loggedOut = "session.logged.out"
    case invalidated = "session.invalidated"
}

public struct SNOWAMBGlideStatus: Equatable {
    
    public let ambActive: Bool
    public let sessionStatus: AMBGlideSessionStatus?
    
    public static func == (lhs: SNOWAMBGlideStatus, rhs: SNOWAMBGlideStatus) -> Bool {
        return lhs.ambActive == rhs.ambActive &&
            lhs.sessionStatus == rhs.sessionStatus
    }
    
}

//
// SNOWAMBClientDelegate
//

public protocol SNOWAMBClientDelegate: AnyObject {
    func ambClientDidConnect(_ client: SNOWAMBClient)
    func ambClientDidDisconnect(_ client: SNOWAMBClient)
    func ambClient(_ client: SNOWAMBClient, didSubscribeToChannel channel: String)
    func ambClient(_ client: SNOWAMBClient, didUnsubscribeFromchannel channel: String)
    func ambClient(_ client: SNOWAMBClient, didReceiveMessage: SNOWAMBMessage, fromChannel channel: String)
    func ambClient(_ client: SNOWAMBClient, didChangeClientStatus status: SNOWAMBClientStatus)
    func ambClient(_ client: SNOWAMBClient, didReceiveGlideStatus status: SNOWAMBGlideStatus)
    func ambClient(_ client: SNOWAMBClient, didFailWithError error: SNOWAMBError)
}

//
// SNOWAMBClientStatus
//

public enum SNOWAMBClientStatus {
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
// MARK: SNOWAMBClient
//

public class SNOWAMBClient {
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
    
    weak public var delegate: SNOWAMBClientDelegate?
    let httpClient: SNOWHTTPSessionClientProtocol
    
    public var clientId: String?
    
    public var maximumRetryAttempts = 5
    
    private var subscriptionsByChannel = [String : [SNOWAMBSubscriptionWeakWrapper]]()
    private var subscribedChannels = Set<String>()
    private var queuedSubscriptionChannels = Set<String>()
    private var longPollingInterval: TimeInterval = 0.0
    private var longPollingTimeout: TimeInterval = 0.0
    private let retryInterval: TimeInterval = 1.0
    private var retryAttempt = 0
    private var reopenChannelsAfterSuccessfulConnectMessages = true
    private var dataTasks = [URLSessionDataTask]()
    
    private var scheduledConnectTask: DispatchWorkItem?
    private var connectDataTask: URLSessionDataTask?
    private var messageId = 0
    
    public var clientStatus = SNOWAMBClientStatus.disconnected {
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
                                      didFailWithError: SNOWAMBError.connectFailed(description: "Maximum connect retry attempts have been reached"))
                }
            }
        }
    }
    
    public var glideStatus: SNOWAMBGlideStatus = SNOWAMBGlideStatus(ambActive: false, sessionStatus: nil) {
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
                    self.clientStatus = .retrying
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
    
    // MARK: public methods
    
    public func connect() {
        sendBayeuxHandshakeMessage()
    }
    
    public func publishMessage(_ message: SNOWAMBMessageDictionary,
                               toChannel channel: String,
                               withExtension ext: SNOWAMBMessageDataExtention? = nil,
                               completion handler: @escaping SNOWAMBPublishMessageHandler) {
        sendBayeuxPublishMessage(message, toChannel: channel, withExtension: ext, completion: handler)
    }
    
    public func subscribe(channel: String, messageHandler: @escaping SNOWAMBMessageHandler) -> SNOWAMBSubscription {
        cleanupSubscriptions()
        
        let subscription = SNOWAMBSubscription(channel: channel, client: self, messageHandler: messageHandler)
        let newWrapper = SNOWAMBSubscriptionWeakWrapper(subscription)
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
        sendBayeuxSubscribeMessage(channel: channel)
    }
    
    public func unsubscribe(subscription: SNOWAMBSubscription) {
        cleanupSubscriptions()

        guard var subscriptions = subscriptionsByChannel[subscription.channel] else {
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
    }
    
    public func tearDown() {
        cancelAllDataTasks()
        self.clientStatus = .disconnected
    }
}

//
// MARK: Private methods
//

private extension SNOWAMBClient {
    
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
    
    // MARK: AMB/Bayeux message handlers
    
    func parseResponseObject(_ responseObject: Any?) -> SNOWAMBResult<[SNOWAMBMessage]> {
        var parsedMessages = [SNOWAMBMessage]()
        
        guard responseObject as? [SNOWAMBMessageDictionary] != nil else {
            let error = SNOWAMBError.messageParserError(description: "messages are not packaged in array")
            delegate?.ambClient(self, didFailWithError: error)
            return SNOWAMBResult.failure(error)
        }
        
        for rawMessage in (responseObject as! [AnyObject]) {
            guard rawMessage as? SNOWAMBMessageDictionary != nil else {
                let error = SNOWAMBError.messageParserError(description: "message is not Dictionary")
                delegate?.ambClient(self, didFailWithError: error)
                return SNOWAMBResult.failure(error)
            }
            do {
                if let ambMessage = try SNOWAMBMessage(rawMessage: rawMessage) {
                   handleAMBMessage(ambMessage)
                    // messages with data/payload are passed through subscription handler and corresponding delegate.
                    // here we return response messages without payload
                    if ambMessage.data == nil {
                       parsedMessages.append(ambMessage)
                    }
                }
            } catch {
                let error = SNOWAMBError.messageParserError(description: "message is not well formatted")
                delegate?.ambClient(self, didFailWithError: error)
                return SNOWAMBResult.failure(error)
            }
        }
        return SNOWAMBResult.success(parsedMessages)
    }
    
    private func handleAMBMessage(_ ambMessage: SNOWAMBMessage) {
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
    
    func handleChannelMessage(_ ambMessage: SNOWAMBMessage, channel: String) {
        if self.isPaused {
            log("incoming message when client is paused. Skipping.")
            return
        }
        
        if subscribedChannels.contains(channel) {
            guard ambMessage.data != nil else {
                return
            }
            if let subscriptionWrappers = subscriptionsByChannel[channel] {
                subscriptionWrappers.forEach({ subscriptionWrapper in
                    if let subscription = subscriptionWrapper.subscription {
                        subscription.messageHandler(SNOWAMBResult.success(ambMessage), subscription)
                    }
                })
            } else {
                // no handler for this channel, using delegate
                delegate?.ambClient(self, didReceiveMessage: ambMessage, fromChannel: channel)
            }
        } else {
            // message was received for a channel client is not subscribed to
            delegate?.ambClient(self,
                              didFailWithError: SNOWAMBError.unhandledMessageReceived(channel: channel))
        }
    }
    
    func handleHandshakeMessage(_ ambMessage: SNOWAMBMessage) {
        if ambMessage.successful {
            retryAttempt = 0
            self.clientId = ambMessage.clientId
            self.clientStatus = .connected
        } else {
            delegate?.ambClient(self,
                              didFailWithError: SNOWAMBError.handshakeFailed(description: "AMB could not handshake with error:\(ambMessage.errorString ?? "")"))
        }
        self.reopenChannelsAfterSuccessfulConnectMessages = true
        startConnectRequest()
    }

    func subscribeQueuedChannels() {
        queuedSubscriptionChannels.forEach({ sendBayeuxSubscribeMessage(channel: $0) })
    }
    
    func reopenSubscriptions() {
        let oldSubscribedChannels = subscribedChannels.union(queuedSubscriptionChannels)
        subscribedChannels.removeAll()
        queuedSubscriptionChannels.removeAll()
        
        oldSubscribedChannels.forEach({ (channel) in
            resubscribe(channel: channel)
        })
    }
    
    func handleConnectMessage(_ ambMessage: SNOWAMBMessage) {
        
        func parseGlideSessionStatus(from ext: [String : Any]) {
            let sessionStatus: AMBGlideSessionStatus?
            if let sessionStatusString = ext["glide.session.status"] as? String {
                sessionStatus = AMBGlideSessionStatus(rawValue: sessionStatusString)
            } else {
                sessionStatus = nil
            }
            
            let ambActive = ext["glide.amb.active"] as? Bool ?? false
            
            glideStatus = SNOWAMBGlideStatus(ambActive: ambActive, sessionStatus: sessionStatus)
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
                delegate?.ambClient(self, didFailWithError: SNOWAMBError.connectFailed(description: "success flag was set to false by server"))
            }
        }
    }
    
    func handleDisconnectMessage(_ ambMessage : SNOWAMBMessage) {
        if ambMessage.successful {
            cancelAllDataTasks()
            subscribedChannels.removeAll()
            subscriptionsByChannel.removeAll()
        } else {
            delegate?.ambClient(self, didFailWithError: SNOWAMBError.disconnectFailed)
        }
    }
    
    func handleSubscribeMessage(_ ambMessage : SNOWAMBMessage) {
        if ambMessage.successful {
            guard let channel = ambMessage.subscription else {
                return
            }
            subscribedChannels.insert(channel)
            if let subscriptions = subscriptionsByChannel[channel] {
                var updatedSubscriptions = [SNOWAMBSubscriptionWeakWrapper]()
                subscriptions.forEach({ (subscriptionWrapper) in
                    if let subscription = subscriptionWrapper.subscription {
                        subscription.subscribed = true
                        let updatedWrapper = SNOWAMBSubscriptionWeakWrapper(subscription)
                        updatedSubscriptions.append(updatedWrapper)
                    }
                })
                subscriptionsByChannel[channel] = updatedSubscriptions
                delegate?.ambClient(self, didSubscribeToChannel: channel)
            }
        } else {
            delegate?.ambClient(self, didFailWithError: SNOWAMBError.disconnectFailed)
        }
    }
    
    func handleUnsubscribeMessage(_ ambMessage : SNOWAMBMessage) {
        if ambMessage.successful {
            subscribedChannels.remove(ambMessage.channel)
            cleanupSubscriptions()
            delegate?.ambClient(self, didUnsubscribeFromchannel: ambMessage.channel)
        } else {
            delegate?.ambClient(self, didFailWithError: SNOWAMBError.disconnectFailed)
        }
    }

    // MARK: Bayeux messages
    
    func sendBayeuxHandshakeMessage() {
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
                              didFailWithError: SNOWAMBError.connectFailed(description: "Connect message can't be send because clientId is not received yet"))
            return
        }
        
        let message = [
            "channel" : AMBChannel.connect.name,
            "clientId" : clientId,
            "supportedConnections" : bayeuxSupportedConnections
        ] as [String : Any]
        
        var timeout : TimeInterval = self.longPollingInterval
        if self.clientStatus == .retrying {
            timeout = 10.0
        }
        
        postBayeuxMessage(message, timeout: timeout)
    }
    
    func sendBayeuxSubscribeMessage(channel: String) {
        guard let clientId = self.clientId else {
            delegate?.ambClient(self, didFailWithError: SNOWAMBError.subscribeFailed)
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
            delegate?.ambClient(self, didFailWithError: SNOWAMBError.unsubscribeFailed)
            return
        }
        
        let message  = [
            "channel" : AMBChannel.unsubscribe.name,
            "clientId" : clientId,
            "subscription" : channel
        ] as [String : Any]
        
        postBayeuxMessage(message)
    }
    
    func sendBayeuxPublishMessage(_ message: SNOWAMBMessageDictionary,
                                  toChannel channel: String,
                                  withExtension ext: SNOWAMBMessageDataExtention? = nil,
                                  completion handler: SNOWAMBPublishMessageHandler? = nil) {
        
        guard clientStatus == .connected else {
            delegate?.ambClient(self,
                              didFailWithError: SNOWAMBError.publishFailed(description: "client not connected to server"))
            return
        }
        
        guard let clientId = self.clientId else {
            delegate?.ambClient(self,
                              didFailWithError: SNOWAMBError.publishFailed(description: "clientId was not set yet"))
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
    
    @discardableResult func postBayeuxMessage(_ message: [String : Any],
                                              timeout: TimeInterval = 0.0,
                                              completion handler: SNOWAMBPublishMessageHandler? = nil) -> URLSessionDataTask? {
        
        func channelNameToPath(_ channel : String) -> String {
            var path = ""
            if channel.hasPrefix("/meta") {
                let parts = channel.split(separator: "/").map(String.init)
                guard let lastPart = parts.last else {
                    return ""
                }
                switch lastPart {
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
        
        guard let channel = message["channel"] as? String else {
            delegate?.ambClient(self,
                              didFailWithError:SNOWAMBError.httpRequestFailed(description: "message is missing a channel field"))
            return nil
        }
        
        var myMessage = message
        myMessage["messageId"] = String(messageId)
        messageId += 1

        let path = channelNameToPath(channel)
        let fullPath = String(format:"/amb/%@", path)
        let task = httpClient.post(fullPath, jsonParameters: myMessage as Any, timeout: timeout,
            success: { [weak self] (responseObject: Any?) -> Void in
                let result = self?.parseResponseObject(responseObject)
                if let handler = handler,
                   let result = result {
                    handler(result)
                }
            },
            failure: { [weak self] (error: Any?) -> Void in
                let httpError = error as! Error
                if let handler = handler {
                    handler(SNOWAMBResult.failure(SNOWAMBError.httpRequestFailed(description: httpError.localizedDescription)))
                }
                self?.handleHTTPResponseError(message: myMessage, error: httpError)
        })

        if let task = task {
            if channel == AMBChannel.connect.name {
                connectDataTask = task
            }
            dataTasks.append(task)
        }
        cleanupCompletedDataTasks()
        
        return task
    }
    
    func handleHTTPResponseError(message: SNOWAMBMessageDictionary, error: Error) {
        cleanupCompletedDataTasks()
        
        if self.isPaused {
            log("AMB Client. HTTP Error \(error.localizedDescription) received. Ignoring because client is paused")
            return
        }

        delegate?.ambClient(self,
                          didFailWithError: SNOWAMBError.httpRequestFailed(description: "request failed with error:\(error.localizedDescription)"))
        if self.clientStatus == .handshake {
            delegate?.ambClient(self,
                              didFailWithError: SNOWAMBError.handshakeFailed(description: "Handshake request failed"))
            return
        }
        if self.clientStatus == .connected {
            self.clientStatus = .retrying
        }
        startConnectRequest(after: retryInterval)
    }
    
}

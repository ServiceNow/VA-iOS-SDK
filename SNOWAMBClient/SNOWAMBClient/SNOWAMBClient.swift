import Foundation

public typealias SNOWAMBMessageDictionary = [String : Any]
public typealias SNOWAMBMessageDataExtention = [String : Any]
public typealias SNOWAMBMessageHandler = (SNOWAMBResult<SNOWAMBMessage>, SNOWAMBSubscription) -> Void

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
}

public struct SNOWAMBGlideStatus {
    let ambActive: Bool
    let sessionStatus: String?
    
    init(ambActive: Bool, sessionStatus: String?) {
        self.ambActive = ambActive
        self.sessionStatus = sessionStatus
    }
    
    static public func != (lhs: SNOWAMBGlideStatus, rhs: SNOWAMBGlideStatus) -> Bool {
        return lhs.ambActive != rhs.ambActive ||
               lhs.sessionStatus != rhs.sessionStatus
    }
}

//
// SNOWAMBClientDelegate
//

public protocol SNOWAMBClientDelegate: class {
    func didConnect(client: SNOWAMBClient)
    func didDisconnect(client: SNOWAMBClient)
    func didFail(client: SNOWAMBClient, withError: SNOWAMBError)
    func didSubscribe(client: SNOWAMBClient, toChannel: String)
    func didUnsubscribe(client: SNOWAMBClient, fromchannel: String)
    func didReceive(client: SNOWAMBClient, message: SNOWAMBMessage, fromChannel channel: String)
    func didClientStatusChange(client: SNOWAMBClient, status: SNOWAMBClientStatus)
    func didGlideStatusChange(client: SNOWAMBClient, status: SNOWAMBGlideStatus)
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
    
    weak var delegate: SNOWAMBClientDelegate?
    let httpClient: SNOWHTTPSessionClientProtocol
    
    public var clientId: String?
    
    public var maximumRetryAttempts = 5
    
    private var subscriptionsByChannel = [String : [SNOWAMBSubscriptionWeakWrapper]]()
    private var subscribedChannels = Set<String>()
    private var queuedSubscriptionChannels = Set<String>()
    private var longPollingInterval: TimeInterval = 0.0
    private var longPollingTimeout: TimeInterval = 0.0
    private let retryInterval = 1.0
    private var retryAttempt = 0
    private var reopenChannelsAfterSuccessfulConnectMessages = true
    private var dataTasks = [URLSessionDataTask]()
    
    private var scheduledConnectTask: DispatchWorkItem?
    // TODO: will probably don't need to keep reference to http data task.
    // it's used for debugging for now (alex a, 02-15-18)
    private weak var connectDataTask: URLSessionDataTask?
    // sequential message id
    private var messageId = 0
    
    public var clientStatus = SNOWAMBClientStatus.disconnected {
        didSet {
            if oldValue != self.clientStatus {
                delegate?.didClientStatusChange(client: self, status: self.clientStatus)
                switch self.clientStatus {
                case .retrying, .handshake:
                    retryAttempt = 0
                case .connected:
                    subscribeQueuedChannels()
                case .disconnected:
                    cancelAllDataTasks()
                case .maximumRetriesReached:
                    delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.connectFailed, "Maximum connect retry attempts have been reached"))
                }
            }
        }
    }
    
    public var glideStatus: SNOWAMBGlideStatus = SNOWAMBGlideStatus(ambActive: false, sessionStatus: nil) {
        didSet {
            if oldValue != self.glideStatus {
                delegate?.didGlideStatusChange(client: self, status: self.glideStatus)
            }
        }
    }
    
    public var paused: Bool = false {
        didSet {
            if paused != oldValue {
                if paused {
                    cancelAllDataTasks()
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
            NSLog(logString)
        #endif
    }
    
    // MARK: public methods
    
    public func connect() {
        sendBayeuxHandshakeMessage()
    }
    
    public func reconnectIfNeeded() {
        startConnectRequest()
    }
    
    public func publishMessage(_ message: SNOWAMBMessageDictionary,
                               toChannel channel: String,
                               withExtension ext: SNOWAMBMessageDataExtention) {
        sendBayeuxPublishMessage(message, toChannel: channel, withExtension: ext)
    }
    
    public func subscribe(channel: String, messageHandler: @escaping SNOWAMBMessageHandler) -> SNOWAMBSubscription {
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
    
    // TODO: Probably move to SMOWAMBSubscription
    public func resubscribe(subscription: SNOWAMBSubscription) {
        if subscribedChannels.contains(subscription.channel) {
            subscription.subscribed = true
            return
        }
        sendBayeuxSubscribeMessage(channel: subscription.channel)
    }
    
    public func unsubscribe(subscription: SNOWAMBSubscription) {
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
        
        guard !paused else {
            log("Client is paused. Connect request is skipped")
            return
        }
        
        guard self.clientStatus != .disconnected else {
            log("Client is disconnected. Connect request is skipped. Handshake must be completed first")
            return
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
    
    // MARK: AMB/Bayeux message handlers
    
    private func parseResponseObject(_ responseObject: Any?) {
        // TODO: For debugging purposes (remove!)
        log("<<<<<<<<<<<<  \(String(describing: responseObject))")
        
        guard responseObject as? [SNOWAMBMessageDictionary] != nil else {
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.messageParserError, "AMB Messages structure is not Array"))
            return
        }
        
        for rawMessage in (responseObject as! [AnyObject]) {
            guard rawMessage as? SNOWAMBMessageDictionary != nil else {
                delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.messageParserError, "AMB Message is not Dictionary"))
                return
            }
            do {
                if let ambMessage = try SNOWAMBMessage(rawMessage: rawMessage) {
                    parseAMBMessage(ambMessage)
                }
            } catch {
                delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.messageParserError, "AMB Message is not well formatted"))
            }
        }
    }
    
    private func parseAMBMessage(_ ambMessage: SNOWAMBMessage) {
        guard let channel = ambMessage.channel else {
            return
        }
        
        switch channel {
        case AMBChannel.handshake.name:
            parseHandshakeMessage(ambMessage)
            
        case AMBChannel.connect.name:
            parseConnectMessage(ambMessage)
            
        case AMBChannel.disconnect.name:
            parseDisconnectMessage(ambMessage)
            
        case AMBChannel.subscribe.name:
            parseSubscribeMessage(ambMessage)
            
        case AMBChannel.unsubscribe.name:
            parseUnsubscribeMessage(ambMessage)
            
        default:
            parseChannelMessage(ambMessage, channel: channel)
        }
    }
    
    func parseChannelMessage(_ ambMessage: SNOWAMBMessage, channel: String) {
        if self.paused {
            log("AMB Client: incoming message when client is paused. Skipping.)
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
                delegate?.didReceive(client: self, message: ambMessage, fromChannel: channel)
            }
        } else {
            // message was received for a channel client is not subscribed to
            delegate?.didFail(client: self,
                              withError: SNOWAMBError(SNOWAMBErrorType.unhandledMessageReceived, "AMB Client: Unhandled Bayuex message: \(ambMessage) for channel: \(channel)"))
        }
    }
    
    func parseHandshakeMessage(_ ambMessage: SNOWAMBMessage) {
        if ambMessage.successful {
            retryAttempt = 0
            self.clientId = ambMessage.clientId
            self.clientStatus = .connected
        } else {
            delegate?.didFail(client: self,
                              withError: SNOWAMBError(SNOWAMBErrorType.handshakeFailed, "Faye could not handshake with error:\(ambMessage.errorString ?? "")"))
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
            if let subscriptions = subscriptionsByChannel[channel] {
                subscriptions.forEach({ (subscriptionWrapper) in
                    if let subscription = subscriptionWrapper.subscription {
                        resubscribe(subscription: subscription)
                    }
                })
            }
        })
    }
    
    func parseConnectMessage(_ ambMessage: SNOWAMBMessage) {
        
        func parseGlideSessionStatus(_ ext: [String : Any]?) {
            if let ext = ext {
                self.glideStatus = SNOWAMBGlideStatus(ambActive: ext["glide.amb.active"] as? Bool ?? false,
                                                      sessionStatus: ext["glide.session.status"] as? String)
            }
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
    
            parseGlideSessionStatus(ambMessage.ext)
            
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
                    log("AMB Client: Delaying connection by: \(interval)")
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
                delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.connectFailed, "AMB Connect was unsuccessful"))
            }
        }
    }
    
    func parseDisconnectMessage(_ ambMessage : SNOWAMBMessage) {
        if ambMessage.successful {
            cancelAllDataTasks()
            subscribedChannels.removeAll()
            subscriptionsByChannel.removeAll()
        } else {
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.disconnectFailed, "AMB Disconnect was unsuccessful"))
        }
    }
    
    func parseSubscribeMessage(_ ambMessage : SNOWAMBMessage) {
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
            }
        } else {
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.disconnectFailed, "AMB Subscribe was unsuccessful"))
        }
    }
    
    func parseUnsubscribeMessage(_ ambMessage : SNOWAMBMessage) {
        if ambMessage.successful {
            guard let channel = ambMessage.channel else {
                return
            }
            subscribedChannels.remove(channel)
        } else {
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.disconnectFailed, "AMB Unsubscribe was unsuccessful"))
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
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.connectFailed, "Connect message can't be send because clientId is not received yet"))
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
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.subscribeFailed, "AMB Subscription for channel\(channel) can't be done. clientId was not set yet"))
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
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.unsubscribeFailed, "AMB Unsubscription for channel\(channel) can't be done. clientId was not set yet"))
            return
        }
        
        let message  = [
            "channel" : AMBChannel.unsubscribe.name,
            "clientId" : clientId,
            "subscription" : channel
        ] as [String : Any]
        
        postBayeuxMessage(message)
    }
    
    func sendBayeuxPublishMessage(_ message: SNOWAMBMessageDictionary, toChannel channel: String, withExtension ext: SNOWAMBMessageDataExtention?) {
        
        guard clientStatus == .connected else {
            delegate?.didFail(client: self,
                              withError: SNOWAMBError(SNOWAMBErrorType.publishFailed, "AMB Publish failed. Client not connected to server"))
            return
        }
        
        guard let clientId = self.clientId else {
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.publishFailed, "AMB Publish for channel\(channel) can't be done. clientId was not set yet"))
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
        
        postBayeuxMessage(bayeuxMessage)
    }
    
    @discardableResult func postBayeuxMessage(_ message: [String : Any], timeout : TimeInterval = 0.0) -> URLSessionDataTask? {
        
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
            delegate?.didFail(client: self, withError:SNOWAMBError(SNOWAMBErrorType.httpRequestFailed, "AMB Message is missing a channel name"))
            return nil
        }
        
        var myMessage = message
        myMessage["messageId"] = String(messageId)
        messageId += 1

        let path = channelNameToPath(channel)
        let fullPath = String(format:"/amb/%@", path)
        
        // TODO: Remove it. For debugging purposes!
        log(">>>>>>>>>>>>>> AMB HTTP Post: \(myMessage)")
        
        let task = httpClient.post(fullPath, jsonParameters: myMessage as Any, timeout: timeout,
            success: { (responseObject: Any?) -> Void in
                self.parseResponseObject(responseObject)
            },
            failure: { (error: Any?) -> Void in
                self.handleHTTPResponseError(message: myMessage, error: error as! Error)
        })

        if let task = task {
            dataTasks.append(task)
            if channel == AMBChannel.connect.name {
                connectDataTask = task
            }
        }
        cleanupCompletedDataTasks()
        
        return task
    }
    
    private func handleHTTPResponseError(message: SNOWAMBMessageDictionary, error: Error) {
        cleanupCompletedDataTasks()

        delegate?.didFail(client: self,
                          withError: SNOWAMBError(SNOWAMBErrorType.httpRequestFailed, "AMB HTTP Request failed with error:\(error)"))
        if self.clientStatus == .handshake {
            delegate?.didFail(client: self,
                              withError: SNOWAMBError(SNOWAMBErrorType.handshakeFailed, "AMB Handshake failed"))
            return
        }
        if self.clientStatus == .connected {
            self.clientStatus = .retrying
        }
        startConnectRequest(after: retryInterval)
    }
    
}

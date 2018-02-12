import Foundation

public typealias SNOWAMBMessageDictionary = [String : Any]
public typealias SNOWAMBMessageDataExtention = [String : Any]
public typealias SNOWAMBMessageHandler = (SNOWAMBResult<SNOWAMBMessage>, SNOWAMBSubscription) -> Void

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
    func didChangeStatus(client: SNOWAMBClient, status: SNOWAMBClientStatus)
}

//
// SNOWAMBClientStatus
//

public enum SNOWAMBClientStatus {
    case disconnected
    case handshake
    case connected
    case retrying
    case maximumHandshakeRetriesReached
}

enum AMBChannel {
    case handshake
    case connect
    case disconnect
    case subscribe
    case unsubscribe
    
    var name : String {
        switch self {
        case .handshake:
            return "/meta/handshake"
        case .connect:
            return "/meta/connect"
        case .disconnect:
            return "/meta/disconnect"
        case .subscribe:
            return "/meta/subscribe"
        case .unsubscribe:
            return "/meta/unsubscribe"
        }
    }
}

extension AMBChannel : CustomStringConvertible {
    var description : String {
        return self.name
    }
}

//
// MARK: SNOWAMBClient
//

public class SNOWAMBClient {
    let BayeuxSupportedConnections = ["long-polling"]
    let BayeuxProtocol = "1.0"
    let BayeuxMinimumSupportedProtocol = "1.0"
    
    enum ReconnectAdviceField {
        case handshake
        case retry
        
        var name : String {
            switch self {
            case .handshake:
                return "handshake"
            case .retry:
                return "retry"
            }
        }
    }
    
    weak var delegate: SNOWAMBClientDelegate?
    let httpClient: SNOWHTTPSessionClientProtocol
    
    public var clientId: String?
    
    private var subscriptionsByChannel = [String : [SNOWAMBSubscriptionWeakWrapper]]()
    private var subscribedChannels = Set<String>()
//    private var pendingSubscriptions = Set<SNOWAMBSubscriptionWeakWrapper>
    private var longPollingInterval : TimeInterval = 0.0
    private var longPollingTimeout : TimeInterval = 0.0
    private let retryInterval = 1.0
    private var retryAttempt = 0
    private var reopenChannelsAfterSuccessfulConnectMessages = true
    private var dataTasks = [Int : URLSessionDataTask]()
//    private var connectDataTask : URLSessionDataTask?
    
    private var scheduledConnectTask: DispatchWorkItem?
    private var messageId = 0
    
    public var clientStatus: SNOWAMBClientStatus = .disconnected {
        willSet(newClientStatus) {
            if newClientStatus != self.clientStatus {
                delegate?.didChangeStatus(client: self, status: newClientStatus)
                if newClientStatus == .retrying {
                    retryAttempt = 0
                }
            }
        }
    }
    
    public var paused: Bool = false {
        didSet(newPauseState) {
            if newPauseState != self.paused {
                if newPauseState {
                    // TODO: Think what to do here exactly!
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
    
    // MARK: public methods
    
    public func connect() {
        sendBayeuxHandshakeMessage()
    }
    
    public func reconnectIfNeeded() {
        startConnectRequest()
    }
    
    public func publishMessage(_ message: String, toChannel: String) {
        //sendBayeuxPublishMessage()
        //TODO: Implement!!!
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
        } else {
            subscriptionsByChannel[channel]?.append(newWrapper)
        }

        sendBayeuxSubscribeMessage(channel: channel)
        
        return subscription
    }
    
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
        
        subscription.subscribed = false
        
        subscriptions = subscriptions
            .filter( { (subscriptionWrapper) in
                    subscriptionWrapper.subscription?.subscribed ?? false
            })

        let needToUnsubscribe = subscriptions.isEmpty
        
        if needToUnsubscribe {
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
            return
        }
        
        if let scheduledConnectTask = self.scheduledConnectTask {
            if !scheduledConnectTask.isCancelled {
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
    
    func cancelConnectRequest() {
        guard scheduledConnectTask != nil else {
            return
        }
        
        cancelAllDataTasks()
        
        if scheduledConnectTask != nil {
            scheduledConnectTask?.cancel()
        }
    }
    
    func cancelAllDataTasks() {
//        connectDataTask?.cancel()
        dataTasks.forEach( {
            (id, task) in task.cancel()
        })
    }
    
    // MARK: AMB/Bayeux message handlers
    
    private func parseResponseObject(_ responseObject: Any?) {
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
            if subscribedChannels.contains(channel) {
                let subscriptionWrappers = subscriptionsByChannel[channel]
                if subscriptionWrappers != nil {
                    subscriptionWrappers?.forEach( { subscriptionWrapper in
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
    }
    
    func parseHandshakeMessage(_ ambMessage: SNOWAMBMessage) {
        if ambMessage.successful {
            retryAttempt = 0
            self.clientId = ambMessage.clientId
            self.clientStatus = SNOWAMBClientStatus.handshake
        } else {
            delegate?.didFail(client: self,
                              withError: SNOWAMBError(SNOWAMBErrorType.handshakeFailed, "Faye could not handshake with error:\(ambMessage.errorString ?? "")"))
        }
        self.reopenChannelsAfterSuccessfulConnectMessages = true
        startConnectRequest()
    }
    
    func parseConnectMessage(_ ambMessage: SNOWAMBMessage) {
        
        func reopenSubscriptions() {
            //let oldSubscribedChannels = subscribedChannels.map { $0 }
            let oldSubscribedChannels = subscribedChannels
            subscribedChannels.removeAll()
            
            oldSubscribedChannels.forEach( { (channel) in
                if let subscriptions = subscriptionsByChannel[channel] {
                    subscriptions.forEach( { (subscriptionWrapper) in
                        if let subscription = subscriptionWrapper.subscription {
                            resubscribe(subscription: subscription)
                        }
                    })
                }
            })
        }
        
        if  let advice = ambMessage.advice,
            let reconnectAdvice = advice["reconnect"] as? String {
            if reconnectAdvice == "handshake" {
                sendBayeuxHandshakeMessage()
                return
            }
        }
        
        if ambMessage.successful {
            if self.reopenChannelsAfterSuccessfulConnectMessages {
                self.reopenChannelsAfterSuccessfulConnectMessages = false
                reopenSubscriptions()
            }
            
            if self.clientStatus == .retrying {
                self.clientStatus = .connected
            }
            
            if  let advice = ambMessage.advice {
                let interval = advice["interval"] as? TimeInterval ?? 0.0
                if let timeout = advice["timeout"] as? TimeInterval {
                    self.longPollingTimeout = timeout
                }
                
                if interval > 0 {
                    NSLog("AMB Client: Delaying connection by: \(interval)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                        self.sendBayeuxConnectMessage()
                    }
                } else {
                    sendBayeuxConnectMessage()
                }
            }
        } else {
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.connectFailed, "AMB Connect was unsuccessful"))
        }
    }
    
    func parseDisconnectMessage(_ ambMessage : SNOWAMBMessage) {
        cancelAllDataTasks()
        subscribedChannels.removeAll()
    }
    
    func parseSubscribeMessage(_ ambMessage : SNOWAMBMessage) {
        guard let channel = ambMessage.channel else {
            return
        }
        subscribedChannels.insert(channel)
    }
    
    func parseUnsubscribeMessage(_ ambMessage : SNOWAMBMessage) {
        guard let channel = ambMessage.channel else {
            return
        }
        
        subscribedChannels.remove(channel)
    }

    // MARK: Bayeux messages
    
    func sendBayeuxHandshakeMessage() {
        let message =
           ["channel" : AMBChannel.handshake.name,
            "version" : BayeuxProtocol,
            "minimumVersion" : BayeuxMinimumSupportedProtocol,
            "supportedConnections" : BayeuxSupportedConnections
            ] as [String : Any]
    
        self.clientStatus = SNOWAMBClientStatus.handshake
        postBayeuxMessage(message)
    }
    
    func sendBayeuxConnectMessage(reconnecting : Bool = false) {
        guard let clientId = self.clientId else {
            delegate?.didFail(client: self, withError: SNOWAMBError(SNOWAMBErrorType.connectFailed, "Connect message can't be send because clientId is not received yet"))
            return
        }
        
        let message =
            ["channel" : AMBChannel.connect.name,
             "clientId" : clientId,
             "supportedConnections" : BayeuxSupportedConnections
            ] as [String : Any]
        
        var timeout : TimeInterval = self.longPollingInterval
        if reconnecting {
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
        
//        sentMessageCount += 1
//        let messageId = Data(String(sentMessageCount).utf8).base64EncodedString()
        
        var message = [
            "channel"  : channel,
            "clientId" : clientId,
            "data" : message
//            "id" : messageId // ???
        ]  as [String : Any]
        
        if ext != nil {
            message["ext"] = ext
        }
        
        postBayeuxMessage(message)
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
                case "\(AMBChannel.handshake)":
                    path = lastPart
                case "\(AMBChannel.connect)":
                    path = lastPart
                default:
                    path = ""
                }
            }
            return path
        }
        
        func cleanupCompleteDataTasks() {
            dataTasks = dataTasks.filter( {
                $1.state != URLSessionTask.State.completed
            })
        }
        
        var myMessage = message
        myMessage["messageId"] = String(messageId)
        messageId += 1
        let channel = message["channel"] as? String ?? ""
        let path = channelNameToPath(channel)
        let fullPath = String(format:"/amb/%@", path)
        
        let task = httpClient.post(fullPath, jsonParameters: myMessage as Any, timeout: timeout,
        success: { (responseObject: Any?) -> Void in
            self.parseResponseObject(responseObject)
        },
        failure: { (error: Any?) -> Void in
            self.handleHTTPResponseError(message: myMessage, error: error as! Error)
        })

        if let taskIdentifier = task?.taskIdentifier {
            dataTasks[taskIdentifier] = task
        }
        cleanupCompleteDataTasks()
/*
        if path == "connect" {
            connectDataTask?.cancel()
            connectDataTask = task
        }
*/
        
        return task
    }
    
    private func handleHTTPResponseError(message: SNOWAMBMessageDictionary, error: Error) {
        delegate?.didFail(client: self,
                          withError: SNOWAMBError(SNOWAMBErrorType.httpRequestFailed, "HTTP Request failed with error:\(error)"))
        self.clientStatus = .retrying
        startConnectRequest(after: retryInterval)
    }
    
}

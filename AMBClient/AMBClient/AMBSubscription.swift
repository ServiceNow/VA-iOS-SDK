public class AMBSubscription {
    
    public let uuid: String
    public var valid = false
    public var subscribed = false
    public let channel: String
    
    let client: AMBClient
    let messageHandler: AMBMessageHandler
    
    init(channel: String, client: AMBClient, messageHandler: @escaping AMBMessageHandler) {
        self.channel = channel
        self.client = client
        self.messageHandler = messageHandler
        self.uuid = UUID().uuidString
        self.valid = true
    }
    
    public func tearDown() {
        guard valid else {
            return
        }
        valid = false
        unsubscribe()
    }
    
    public func unsubscribe() {
        client.unsubscribe(subscription: self)
    }
    
}

public class AMBSubscriptionWeakWrapper {
    public weak var subscription: AMBSubscription?
    
    init(_ subscription: AMBSubscription) {
        self.subscription = subscription
    }
    
}

public class SNOWAMBSubscription {
    
    let uuid : String
    var valid = false
    var pending = true
    var subscribed = false
    let client : SNOWAMBClient
    let channel : String
    let messageHandler : SNOWAMBMessageHandler
    
    init(channel : String, client : SNOWAMBClient, messageHandler : @escaping SNOWAMBMessageHandler) {
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
    
    deinit {
        client.unsubscribe(subscription: self)
    }
    
}

public struct SNOWAMBSubscriptionWeakWrapper {
    public weak var subscription : SNOWAMBSubscription?
    
    init(_ subscription : SNOWAMBSubscription) {
        self.subscription = subscription
    }
}

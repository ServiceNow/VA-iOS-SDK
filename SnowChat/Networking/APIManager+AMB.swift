import AMBClient

// MARK: - AMB Transport

extension APIManager {
    
    func sendMessage(_ message: [String: Any], toChannel channel: String,
                     completion handler: AMBPublishMessageHandler? = nil) {
        ambClient.publishMessage(message, toChannel: channel, withExtension:[:],
                                 completion: { (result) in
                                    switch result {
                                    case .success:
                                        Logger.default.logInfo("published message successfully")
                                        //TODO: Implement handler here
                                    case .failure:
                                        Logger.default.logInfo("failed to publish message")
                                        //TODO: same
                                    }
                                    if let handler = handler {
                                        handler(result)
                                    }
        })
    }
    
    func sendMessage<T>(_ message: T, toChannel channel: String, encoder: JSONEncoder,
                        completion handler: AMBPublishMessageHandler? = nil) where T: Encodable {
        do {
            let jsonData = try encoder.encode(message)
            if let dict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                
                if Logger.default.enabled, let jsonString = String(data: jsonData, encoding: .utf8) {
                    Logger.default.logInfo("Publishing to AMB Channel: \(channel): \(jsonString)")
                }
                
                sendMessage(dict, toChannel: channel, completion: handler)
            }
        } catch let err {
            Logger.default.logError("Error publishing: \(err)")
        }
    }
    
    func subscribe(_ channelName: String, messages messageHandler: @escaping AMBMessageHandler) -> AMBSubscription {
        let subscription: AMBSubscription = ambClient.subscribe(channel: channelName, messageHandler: { (result, subscription) in
            switch result {
            case .success:
                if let message = result.value {
                    Logger.default.logInfo("Incoming AMB Message: \(message.jsonDataString)")
                    if message.messageType == .dataMessage {
                        messageHandler(result, subscription)
                    }
                }
            case .failure:
                messageHandler(result, subscription)
            }
        })
        return subscription
    }
        
}

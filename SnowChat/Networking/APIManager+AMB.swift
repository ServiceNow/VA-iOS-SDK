import SNOWAMBClient

// MARK: - AMB Transport

extension APIManager {
    
    func sendMessage(_ message: [String: Any], toChannel channel: String) {
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
        })
    }
    
    func sendMessage<T>(_ message: T, toChannel channel: String, encoder: JSONEncoder) where T: Encodable {
        do {
            let jsonData = try encoder.encode(message)
            if let dict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                
                if Logger.default.enabled, let jsonString = String(data: jsonData, encoding: .utf8) {
                    Logger.default.logInfo("Publishing to AMB Channel: \(channel): \(jsonString)")
                }
                
                sendMessage(dict, toChannel: channel)
            }
        } catch let err {
            Logger.default.logError("Error publishing: \(err)")
        }
    }
    
    func subscribe(_ channelName: String, messages messageHandler: @escaping SNOWAMBMessageHandler) -> SNOWAMBSubscription {
        let subscription: SNOWAMBSubscription = ambClient.subscribe(channel: channelName, messageHandler: { (result, subscription) in
            switch result {
            case .success:
                if let message = result.value {
                    Logger.default.logInfo("Incoming AMB Message: \(message.jsonDataString)")
                    messageHandler(result, subscription)
                }
            case .failure:
                messageHandler(result, subscription)
            }
        })
        return subscription
    }
    
}

// MARK: - AMB Delegate

extension APIManager: SNOWAMBClientDelegate {
    
    func didConnect(client: SNOWAMBClient) {}
    func didDisconnect(client: SNOWAMBClient) {}
    func didSubscribe(client: SNOWAMBClient, toChannel: String) {}
    func didUnsubscribe(client: SNOWAMBClient, fromchannel: String) {}
    func didReceive(client: SNOWAMBClient, message: SNOWAMBMessage, fromChannel channel: String) {}
    func didGlideStatusChange(client: SNOWAMBClient, status: SNOWAMBGlideStatus) {}
    
    func didFail(client: SNOWAMBClient, withError error: SNOWAMBError) {
        Logger.default.logInfo("AMB client error: \(error.localizedDescription)")
    }
    
    func didClientStatusChange(client: SNOWAMBClient, status: SNOWAMBClientStatus) {
        if let transportListener = transportListener {
            switch status {
            case .connected:
                transportListener.apiManagerTransportDidBecomeAvailable(self)
            case .disconnected:
                transportListener.apiManagerTransportDidBecomeUnavailable(self)
            default:
                Logger.default.logInfo("AMB connection notification: \(status)")
            }
        }
    }
    
}

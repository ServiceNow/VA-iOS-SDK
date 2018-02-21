public struct SNOWAMBMessage {
    
    public let id: String
    public let successful: Bool
    public let authSuccessful: Bool?
    public let channel: String?
    public let clientId: String?
    public let version: String?
    public let minimumVersion: String?
    public let supportedConnectionTypes: [String]?
    public let advice: [String: Any]?
    public let errorString: String?
    public let subscription: String?
    public let timestamp: Date?
    public let fromChannel: String?
    public let toChannel: String?
    public let ext: [String : Any]?
    public var data: [String : Any]?
    public var jsonDataString: String
    // TODO: Remove eventually. Using for debugging purposes (alex a, 01-18-17)
    public var jsonFullMessageString: String
    
    init?(rawMessage: Any) throws {
        
        func toJSON(_ data: [String : Any]?) -> String {
            do {
                if let data = data {
                    let jsonData = try JSONSerialization.data(withJSONObject: data as Any, options: .prettyPrinted)
                    return String(data: jsonData, encoding: String.Encoding.utf8) ?? "{}"
                } else {
                    return "{}"
                }
            } catch {
                return "{}"
            }
        }
        
        guard let messageDict = rawMessage as? [String : Any] else {
            throw SNOWAMBError(SNOWAMBErrorType.messageParserError, "AMB Message is not [String:Any] dictionary")
        }
        
        self.id = messageDict["id"] as? String ?? ""
        self.successful = messageDict["successful"] as? Bool ?? true
        self.channel = messageDict["channel"] as? String
        self.clientId = messageDict["clientId"] as? String
        self.authSuccessful = messageDict["authSuccessful"] as? Bool
        self.version = messageDict["version"] as? String
        self.minimumVersion = messageDict["minimumVersion"] as? String
        self.supportedConnectionTypes = messageDict["supportedConnectionTypes"] as? [String]
        self.advice = messageDict["advice"] as? [String : Any]
        self.errorString = messageDict["error"] as? String
        self.subscription = messageDict["subscription"] as? String ?? ""
        self.timestamp = Date(timeIntervalSince1970: (messageDict["timestamp"] as? TimeInterval) ?? 0)
        self.fromChannel = messageDict["fromChannel"] as? String
        self.toChannel = messageDict["toChannel"] as? String
        self.ext = messageDict["ext"] as? [String : Any]
        self.data = messageDict["data"] as? [String : Any]
    
        self.jsonDataString = toJSON(self.data)
        // TODO: Remove eventually. Using for debugging purposes (alex a, 01-18-17)
        self.jsonFullMessageString = toJSON(messageDict)
    }
    
}

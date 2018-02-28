public enum SNOWAMBError: Error {
    case handshakeFailed(description: String)
    case connectFailed(description: String)
    case subscribeFailed
    case unsubscribeFailed
    case publishFailed(description: String)
    case disconnectFailed
    case httpRequestFailed(description: String)
    case messageParserError(description: String)
    case unhandledMessageReceived(channel: String)
}

extension SNOWAMBError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .handshakeFailed(description: let description):
            return "handshake failed (\(description))"
        case .connectFailed(description: let description):
            return "connect failed (\(description))"
        case .subscribeFailed:
            return "subscribe failed"
        case .unsubscribeFailed:
            return "unsubscribe failed"
        case .publishFailed(description: let description):
            return "message publish to channel failed (\(description))"
        case .disconnectFailed:
            return "disconnect failed"
        case .httpRequestFailed(description: let description):
            return "http error (\(description))"
        case .messageParserError(description: let description):
            return "parser error (\(description))"
        case .unhandledMessageReceived(channel: let channel):
            return "message recieved for unsubscribed channel \(channel)"
        }
    }
}

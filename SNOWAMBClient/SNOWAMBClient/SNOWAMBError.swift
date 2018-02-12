public enum SNOWAMBErrorType {
    case handshakeFailed
    case connectFailed
    case subscribeFailed
    case publishFailed
    case unsubscribeFailed
    case disconnectFailed
    case httpRequestFailed
    case messageParserError
    case unhandledMessageReceived
}

public class SNOWAMBError : LocalizedError {
    
    let description: String
    let error: SNOWAMBErrorType
    
    init(_ error: SNOWAMBErrorType, _ description : String) {
        self.description = description
        self.error = error
    }
}

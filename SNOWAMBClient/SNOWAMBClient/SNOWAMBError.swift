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

public class SNOWAMBError : Error {
    
    let description: String
    let errorType: SNOWAMBErrorType
    
    init(_ error: Error) {
        self.errorType = .httpRequestFailed
        self.description = error.localizedDescription
    }
    
    init(_ error: SNOWAMBErrorType, _ description : String) {
        self.description = description
        self.errorType = error
    }
}

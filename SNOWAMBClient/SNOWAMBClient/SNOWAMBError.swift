public struct SNOWAMBError: Error {
    
    enum SNOWAMBErrorType {
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
    
    let errorType: SNOWAMBErrorType
    let description: String
    
    init(_ error: SNOWAMBErrorType, _ description : String) {
        self.errorType = error
        self.description = description
    }
}

public protocol SNOWHTTPSessionClientProtocol {
    var baseURL : URL { get }
    
    func invalidateSessionCancelingTasks(_ cancelingTasks: Bool)
    
    func post(_ URLString: String,
              jsonParameters JSONParameters: Any,
              timeout: TimeInterval,
              success: @escaping (Any?) -> Void,
              failure: @escaping (Error?) -> Void) -> URLSessionDataTask?
}

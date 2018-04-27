import Foundation
import AMBClient

class SNOWTestHTTPClient: SNOWHTTPSessionClientProtocol {

    let baseURL: URL
    let session = URLSession(configuration: .default)
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func invalidateSessionCancelingTasks(_ cancelingTasks: Bool) {
    }
    
    func post(_ URLString: String,
              jsonParameters JSONParameters: Any,
              timeout: TimeInterval,
              success: @escaping (Any?) -> Void,
              failure: @escaping (Error?) -> Void) -> URLSessionDataTask? {
        do {
            let postData = try JSONSerialization.data(withJSONObject: JSONParameters, options: .prettyPrinted)
            let strPostData = String(data: postData, encoding: String.Encoding.utf8) ?? "{}"
            print(strPostData)
            if let url = URL(string: URLString, relativeTo: baseURL) {
                httpRequest(url: url, data: postData) { result in
                    switch result {
                    case .success:
                        success(result.value)
                    case .failure:
                        failure(result.error)
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    private func httpRequest(url: URL, data: Data, completion handler: @escaping (AMBResult<[Any]>) -> Void) {
        
        func toJSON(_ data: Data?) -> [Any] {
            do {
                if let data = data {
                    let strResponse = String(data: data, encoding: String.Encoding.utf8) ?? "{}"
                    print(strResponse)
                    let parsedArray = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
                    return parsedArray ?? []
                } else {
                    return []
                }
            } catch {
                print("json error: \(error.localizedDescription)")
                return []
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let dataTask = session.dataTask(with: request as URLRequest) { data, response, error in
            if let error = error {
                let errorMessage = "http error: " + error.localizedDescription
                if let response = response as? HTTPURLResponse {
                    handler(AMBResult.failure(AMBError.httpRequestFailed(description: "http status code:\(response.statusCode) \(errorMessage)")))
                } else {
                    handler(AMBResult.failure(AMBError.httpRequestFailed(description: "error \(errorMessage)")))
                }
            } else {
                let response = response as? HTTPURLResponse
                if response?.statusCode == 200 {
                   handler(AMBResult.success(toJSON(data)))
                } else {
                    handler(AMBResult.failure(AMBError.httpRequestFailed(description: "http status code:\(response?.statusCode ?? 0)")))
                }
            }
        }
        dataTask.resume()
    }
}

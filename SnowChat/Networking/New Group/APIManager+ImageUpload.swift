//
//  APIManager+ImageUpload.swift
//  SnowChat
//
//  Created by Will Lisac on 2/23/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension APIManager {
    
    func uploadImage(data: Data, withName name: String, taskId: String, completion: @escaping (_ result: String?) -> Void) {
        let url = apiURLWithPath("cs/media/\(taskId)")
        sessionManager.upload(multipartFormData: { multipartData in
            multipartData.append(data, withName: name, fileName: name, mimeType: "image/jpeg")
        }, to: url, encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(request: let upload, streamingFromDisk: _, streamFileURL: _):
                upload.responseJSON { response in
                    let dictionary = response.result.value as? [String : Any] ?? [:]
                    let result = dictionary["result"] as? String
                    completion(result)
                }
                .resume()
                
            case .failure(let error):
                print("Error: \(error)")
            }
        })
    }
    
}

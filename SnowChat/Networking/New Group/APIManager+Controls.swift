//
//  APIManager+Controls.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import AlamofireImage

protocol ControlResourceProvider {
    var imageProvider: ImageDownloader { get }
}

extension APIManager: ControlResourceProvider {
    var imageProvider: ImageDownloader {
        return imageDownloader
    }
    
    func uploadImage(data: Data, withName name: String, taskId: String, completion: @escaping (_ result: String?) -> Void) {
        let url = apiURLWithPath("cs/media/\(taskId)")
        
        sessionManager.upload(multipartFormData: { multipartData in
            multipartData.append(data, withName: name, fileName: name, mimeType: "image/jpeg")
        }, to: url, encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(request: let upload, streamingFromDisk: _, streamFileURL: _):
                upload.responseJSON(completionHandler: { response in
                    let dictionary = response.result.value as? [String : Any] ?? [:]
                    let result = dictionary["result"] as? String
                    completion(result)
                })
            case .failure(let error):
                print("Error: \(error)")
            }
        })
        
    }
}

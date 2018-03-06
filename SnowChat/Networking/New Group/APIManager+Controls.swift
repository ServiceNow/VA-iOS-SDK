//
//  APIManager+Controls.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import AlamofireImage
import WebKit

protocol ControlResourceProvider: ControlWebResourceProvider {
    var imageDownloader: ImageDownloader { get }
    
    var avatarURL: URL { get }
}

protocol ControlWebResourceProvider {
    func authorizedRequest(with url: URL) -> URLRequest
    var webViewConfiguration: WKWebViewConfiguration { get }
}

extension APIManager: ControlResourceProvider {
    
    var avatarURL: URL {
        // TODO: temporary for demo purposes and until we have actual enpoint to fetch the image from.
        return instance.instanceURL.appendingPathComponent("/images/default_virtual_agent_avatar.png")
    }
    
}

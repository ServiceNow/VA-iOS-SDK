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
}

protocol ControlWebResourceProvider {
    func authorizedWebViewInitialRequest(with url: URL) -> URLRequest
    var webViewConfiguration: WKWebViewConfiguration { get }
}

extension APIManager: ControlResourceProvider {

}

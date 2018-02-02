//
//  APIManager+Controls.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import AlamofireImage

protocol ControlResourceProvider {
    var imageDownloader: ImageDownloader { get }
}

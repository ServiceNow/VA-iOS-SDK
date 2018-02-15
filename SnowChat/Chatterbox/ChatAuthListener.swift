//
//  ChatAuthListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/30/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

protocol ChatAuthListener: AnyObject {
    
    func chatterboxAuthenticationDidBecomeInvalid(_ chatterbox: Chatterbox)
    
}

//
//  TypingIndicatorView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class TypingIndicatorView: UIView {
    
    var color: UIColor?
    
    var isAnimating: Bool {
        return false
    }
    
    func startAnimating() {
        
    }
    
    func stopAnimating() {
        
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 50)
    }
}

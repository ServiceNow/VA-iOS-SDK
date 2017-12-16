//
//  MessageView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class MessageView: UIView {
    
    @IBOutlet weak var bubbleView: BubbleView!
    
    override var intrinsicContentSize: CGSize {
        bubbleView.invalidateIntrinsicContentSize()
        let bubbleContentSize = bubbleView.intrinsicContentSize
        var superContentSize = super.intrinsicContentSize
        superContentSize.height = bubbleContentSize.height
        return superContentSize
    }
}

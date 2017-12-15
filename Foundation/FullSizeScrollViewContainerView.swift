//
//  FullSizeScrollViewContainerView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/28/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class FullSizeScrollViewContainerView: UIView {
    
    override var backgroundColor: UIColor? {
        didSet {
            scrollView?.backgroundColor = backgroundColor
        }
    }
    
    var scrollView: UIScrollView? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    var maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        guard let scrollView = scrollView,
            let height = [scrollView.contentSize.height, maxHeight].min() else {
                return super.intrinsicContentSize
        }
        
        let width = scrollView.bounds.width
        return CGSize(width: width, height: height)
    }
}

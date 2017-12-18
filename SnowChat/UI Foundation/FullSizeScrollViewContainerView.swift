//
//  FullSizeScrollViewContainerView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/28/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class FullSizeScrollViewContainerView: UIView {
    
    var observer: NSKeyValueObservation?
    
    override var backgroundColor: UIColor? {
        didSet {
            scrollView?.backgroundColor = backgroundColor
        }
    }
    
    var scrollView: UIScrollView? {
        didSet {
            invalidateIntrinsicContentSize()
            observer = scrollView?.observe(\UIScrollView.contentSize) { [weak self] (scrollView, change) in
                self?.invalidateIntrinsicContentSize()
            }
        }
    }
    
    var maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: CGSize {
        guard let scrollView = scrollView,
            let height = [scrollView.contentSize.height, maxHeight].min() else {
                return super.intrinsicContentSize
        }
        
        let width = scrollView.contentSize.width
        return CGSize(width: width, height: height)
    }
}

//
//  FullSizeScrollViewContainerView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/28/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

protocol ScrollViewContainerDelegate: AnyObject {
    func container(_ container: FullSizeScrollViewContainerView, didChangeContentSize size: CGSize)
}

class FullSizeScrollViewContainerView: UIView {
    
    weak var uiDelegate: ScrollViewContainerDelegate?
    
    // Only when scrollView is UITableView type
    var maxVisibleItemCount: Int?
    
    private var observer: NSKeyValueObservation?
    
    override var backgroundColor: UIColor? {
        didSet {
            scrollView?.backgroundColor = backgroundColor
        }
    }
    
    var scrollView: UIScrollView? {
        didSet {
            observer = scrollView?.observe(\UIScrollView.contentSize) { [weak self] (view, change) in
                guard let strongSelf = self else { return }
                strongSelf.invalidateIntrinsicContentSize()
                strongSelf.uiDelegate?.container(strongSelf, didChangeContentSize: view.contentSize)
            }
        }
    }
    
    var maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        guard let scrollView = scrollView else { return super.intrinsicContentSize }
        guard let height = [scrollView.contentSize.height, maxHeight].min() else {
            return super.intrinsicContentSize
        }
        
        let width = scrollView.contentSize.width
        let size = CGSize(width: width, height: height)
        return size
    }
}

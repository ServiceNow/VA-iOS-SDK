//
//  FullSizeScrollViewContainerView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/28/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

protocol FullSizeScrollViewContainerViewDelegate: AnyObject {
    func fullSizeContainerViewDidInvalidateIntrinsicContentSize(_ fullSizeContainerView: FullSizeScrollViewContainerView)
}

class FullSizeScrollViewContainerView: UIView {
    
    weak var uiDelegate: FullSizeScrollViewContainerViewDelegate?
    
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
            observer = scrollView?.observe(\UIScrollView.contentSize) { [weak self] (scrollView, change) in
                guard let strongSelf = self else { return }
                strongSelf.invalidateIntrinsicContentSize()
                strongSelf.uiDelegate?.fullSizeContainerViewDidInvalidateIntrinsicContentSize(strongSelf)
            }
        }
    }
    
    private func updateMaxHeightForScrollViewIfNeeded(_ scrollView: UIScrollView) {
        // set maxHeight based on the height of visible cell items
        if let tableView = scrollView as? UITableView,
            let visibleItemCount = maxVisibleItemCount,
            !scrollView.bounds.isEmpty {
            maxHeight = maxHeightForTableView(tableView, visibleItemCount: visibleItemCount)
            if maxHeight < scrollView.contentSize.height.rounded(.down) {
                scrollView.isScrollEnabled = true
            } else {
                scrollView.isScrollEnabled = false
            }
        }
    }
    
    private func maxHeightForTableView(_ tableView: UITableView, visibleItemCount count: Int) -> CGFloat {
        
        // update layout to get proper rects
        tableView.layoutIfNeeded()
        
        var totalHeight: CGFloat = 0
        
        totalHeight += tableView.rectForHeader(inSection: 0).height
        totalHeight += tableView.rectForFooter(inSection: 0).height
        
        for rowIndex in 0..<count {
            totalHeight += tableView.rectForRow(at: IndexPath(row: rowIndex, section: 0)).height
        }
        
        return totalHeight.rounded(.down)
    }
    
    var maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        guard let scrollView = scrollView else { return super.intrinsicContentSize }
        updateMaxHeightForScrollViewIfNeeded(scrollView)
        guard let height = [scrollView.contentSize.height, maxHeight].min() else {
            return super.intrinsicContentSize
        }
        
        let width = scrollView.contentSize.width
        return CGSize(width: width, height: height)
    }
}

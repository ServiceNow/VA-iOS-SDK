//
//  FullSizeScrollViewContainerView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/28/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class FullSizeScrollViewContainerView: UIView {
    
    // Only when scrollView is UITableView type
    var maxVisibleItemCount: Int?
    
    var observer: NSKeyValueObservation?
    
    override var backgroundColor: UIColor? {
        didSet {
            scrollView?.backgroundColor = backgroundColor
        }
    }
    
    var scrollView: UIScrollView? {
        didSet {
            observer = scrollView?.observe(\UIScrollView.bounds) { [weak self] (scrollView, change) in
                self?.updateMaxHeightForScrollViewIfNeeded(scrollView)
                self?.invalidateIntrinsicContentSize()
            }
        }
    }
    
    private func updateMaxHeightForScrollViewIfNeeded(_ scrollView: UIScrollView) {
        // set maxHeight based on the height of visible cell items
        if let tableView = scrollView as? UITableView,
            let visibleItemCount = maxVisibleItemCount,
            tableView.visibleCells.count > visibleItemCount {
            maxHeight = maxHeightForTableView(tableView, visibleItemCount: visibleItemCount)
            scrollView.isScrollEnabled = true
        }
    }
    
    private func maxHeightForTableView(_ tableView: UITableView, visibleItemCount count: Int) -> CGFloat {
        var totalHeight: CGFloat = 0
        for rowIndex in 0..<count {
            
            if let headerHeight = tableView.headerView(forSection: 0)?.bounds.height {
                totalHeight += headerHeight
            }
            
            if let footerHeight = tableView.footerView(forSection: 0)?.bounds.height {
                totalHeight += footerHeight
            }
            
            if let rowHeight = tableView.cellForRow(at: IndexPath(row: rowIndex, section: 0))?.bounds.height {
                totalHeight += rowHeight
            }
        }
        
        return totalHeight
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
        
        let width = scrollView.contentSize.width
        return CGSize(width: width, height: height)
    }
}

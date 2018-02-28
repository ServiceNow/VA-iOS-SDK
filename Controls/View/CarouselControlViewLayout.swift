//
//  CarouselControlViewLayout.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/28/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class CarouselControlViewLayout: UICollectionViewFlowLayout {
    
    private let maxItemSize = CGSize(width: 100, height: 100)
    
    override init() {
        super.init()
        scrollDirection = .horizontal
        itemSize = maxItemSize
        minimumLineSpacing = 10
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard self.collectionView != nil else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        return targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }
        
        let jumpWidth = itemSize.width + minimumLineSpacing
        let rest: Int = Int((proposedContentOffset.x + collectionView.contentInset.left + jumpWidth * 0.5) / jumpWidth)
        return CGPoint(x: CGFloat(rest) * jumpWidth - collectionView.contentInset.left, y: proposedContentOffset.y)
    }
}

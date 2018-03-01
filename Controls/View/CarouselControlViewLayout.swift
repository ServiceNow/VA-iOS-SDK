//
//  CarouselControlViewLayout.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/28/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class CarouselControlViewLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        scrollDirection = .horizontal
        itemSize = CGSize(width: 150, height: 150)
        minimumLineSpacing = 20
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else {
            return
        }
        
        let leftContentInset = collectionView.frame.width * 0.5 - itemSize.width * 0.5
        collectionView.contentInset = UIEdgeInsets(top: 0, left: leftContentInset, bottom: 0, right: leftContentInset)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }), let collectionView = collectionView else {
            return super.layoutAttributesForElements(in: rect)
        }
        
        let collectionViewCenter = collectionView.frame.width * 0.5
        guard let centerAttribute = attributes.first(where: { attribute in
            let currentItemXPosition = attribute.frame.origin.x - collectionView.contentOffset.x
            var translatedAttributeFrame = attribute.frame
            translatedAttributeFrame.origin.x = currentItemXPosition
            return translatedAttributeFrame.contains(CGPoint(x: collectionViewCenter, y: 100))
        }) else {
            return attributes
        }
        
        centerAttribute.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        return attributes
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

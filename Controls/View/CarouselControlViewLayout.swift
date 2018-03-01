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
        itemSize = CGSize(width: 150, height: 160)
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
        collectionView.contentInset = UIEdgeInsets(top: 20, left: leftContentInset, bottom: 0, right: leftContentInset)
        headerReferenceSize = CGSize(width: 1, height: 40)
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView,
            elementKind == UICollectionElementKindSectionHeader else {
            return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }
        
        let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?.copy() as! UICollectionViewLayoutAttributes
        var frame = attributes.frame
        frame.origin.x = collectionView.contentOffset.x
        frame.origin.y = -collectionView.contentInset.top
        frame.size.height = headerReferenceSize.height
        frame.size.width = collectionView.frame.width
        attributes.frame = frame
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }), let collectionView = collectionView else {
            return super.layoutAttributesForElements(in: rect)
        }
        
        if let headerAttributes = attributes.first(where: { $0.representedElementKind == UICollectionElementKindSectionHeader }),
            let calculatedHeaderAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: headerAttributes.indexPath) {
            headerAttributes.frame = calculatedHeaderAttributes.frame
        }
        
        let collectionViewCenter = CGPoint(x: collectionView.frame.width * 0.5, y: collectionView.frame.height * 0.5)
        let centerAttribute = attributes.first(where: { attribute in
            
            // we only want to scale items, not headers or footers
            guard attribute.representedElementKind != UICollectionElementKindSectionHeader else {
                return false
            }
            
            let currentItemXPosition = attribute.frame.origin.x - collectionView.contentOffset.x
            var translatedAttributeFrame = attribute.frame
            translatedAttributeFrame.origin.x = currentItemXPosition
            return translatedAttributeFrame.contains(collectionViewCenter)
        })
        
        centerAttribute?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
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
        let reminder: Int = Int((proposedContentOffset.x + collectionView.contentInset.left + jumpWidth * 0.5) / jumpWidth)
        return CGPoint(x: CGFloat(reminder) * jumpWidth - collectionView.contentInset.left, y: proposedContentOffset.y)
    }
}

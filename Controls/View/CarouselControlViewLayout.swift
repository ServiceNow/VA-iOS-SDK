//
//  CarouselControlViewLayout.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/28/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class CarouselControlViewLayout: UICollectionViewFlowLayout {
    
    private(set) var focusedIndexPath = IndexPath(item: 0, section: 0)
    
    private var nextIndexPath: IndexPath {
        let nextItem = min(focusedIndexPath.item + 1, itemCount)
        let indexPath = IndexPath(item: nextItem, section: 0)
        focusedIndexPath = indexPath
        return indexPath
    }
    
    private var previousIndexPath: IndexPath {
        let nextItem = max(focusedIndexPath.item - 1, 0)
        let indexPath = IndexPath(item: nextItem, section: 0)
        focusedIndexPath = indexPath
        return indexPath
    }
    
    private var lastContentOffset = CGPoint.zero
    private var itemCount: Int = 0
    private let verticalInset: CGFloat = 20
    let headerHeight: CGFloat = 50
    
    override init() {
        super.init()
        scrollDirection = .horizontal
        itemSize = CGSize(width: 150, height: 160)
        minimumLineSpacing = 10
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
        collectionView.contentInset = UIEdgeInsets(top: headerHeight + verticalInset, left: leftContentInset, bottom: verticalInset, right: leftContentInset)
        headerReferenceSize = CGSize(width: 1, height: headerHeight)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        itemCount = collectionView.numberOfItems(inSection: 0)
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
        centerAttribute?.zIndex = 100
        return attributes
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard self.collectionView != nil else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        lastContentOffset = targetContentOffset(forProposedContentOffset: proposedContentOffset)
        return lastContentOffset
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        // Find next indexPath for proposed contentOffset. Check for boundary conditions
        let nextIndexPathToFocus: IndexPath
        if lastContentOffset.x < proposedContentOffset.x {
            nextIndexPathToFocus = nextIndexPath
        } else {
            nextIndexPathToFocus = previousIndexPath
        }
        
        return targetContentOffset(for: nextIndexPathToFocus)
    }
    
    func selectNextItem() {
        let nextIndexPathToFocus = nextIndexPath
        let contentOffset = targetContentOffset(for: nextIndexPathToFocus)
        collectionView?.setContentOffset(contentOffset, animated: true)
    }
    
    func selectPreviousItem() {
        let nextIndexPathToFocus = previousIndexPath
        let contentOffset = targetContentOffset(for: nextIndexPathToFocus)
        collectionView?.setContentOffset(contentOffset, animated: true)
    }
    
    private func targetContentOffset(for indexPath: IndexPath) -> CGPoint {
        guard let collectionView = self.collectionView else { return CGPoint.zero }
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            Logger.default.logError("Couldn't find collection cell!")
            return CGPoint(x: collectionView.contentInset.left, y: collectionView.contentOffset.y)
        }
        
        let cellMinX = cell.frame.minX
        return CGPoint(x: cellMinX - collectionView.contentInset.left, y: collectionView.contentOffset.y)
    }
}

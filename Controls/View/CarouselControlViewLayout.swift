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
        let nextItem = min(focusedIndexPath.item + 1, itemCount - 1)
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
    let headerHeight: CGFloat = 50
    let footerHeight: CGFloat = 50
    
    override init() {
        super.init()
        minimumLineSpacing = 10
        scrollDirection = .horizontal
        itemSize = CGSize(width: 150, height: 160)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else {
            return
        }
        
        itemCount = collectionView.numberOfItems(inSection: 0)
        headerReferenceSize = CGSize(width: 1, height: headerHeight)
        footerReferenceSize = CGSize(width: 1, height: footerHeight)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        let horizontalContentInset = collectionView.frame.width * 0.5 - itemSize.width * 0.5
        collectionView.contentInset = UIEdgeInsets(top: 0, left: horizontalContentInset, bottom: 0, right: horizontalContentInset)
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return super.collectionViewContentSize
        }
        
        var collectionViewContentSize = super.collectionViewContentSize
        collectionViewContentSize.height = collectionView.frame.height
        return collectionViewContentSize
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else {
            return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }
        
        let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?.copy() as! UICollectionViewLayoutAttributes
        
        var frame = attributes.frame
        frame.origin.x = collectionView.contentOffset.x
        frame.size.width = collectionView.bounds.width
        
        if elementKind == UICollectionElementKindSectionHeader {
            frame.origin.y = -collectionView.contentInset.top
            frame.size.height = headerReferenceSize.height
        } else if elementKind == UICollectionElementKindSectionFooter {
            frame.origin.y = collectionView.bounds.height - footerReferenceSize.height
            frame.size.height = footerReferenceSize.height
        } else {
            return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }
        
        attributes.frame = frame
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }),
            let collectionView = collectionView else {
            return super.layoutAttributesForElements(in: rect)
        }
        
        // update header position
        if let headerAttributes = attributes.first(where: { $0.representedElementKind == UICollectionElementKindSectionHeader }),
            let calculatedHeaderAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: headerAttributes.indexPath) {
            headerAttributes.frame = calculatedHeaderAttributes.frame
        }
        
        // update footer position
        if let footerAttributes = attributes.first(where: { $0.representedElementKind == UICollectionElementKindSectionFooter }),
            let calculatedFooterAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionFooter, at: footerAttributes.indexPath) {
            footerAttributes.frame = calculatedFooterAttributes.frame
        }
        
        let collectionViewCenter = CGPoint(x: collectionView.frame.width * 0.5, y: collectionView.frame.height * 0.5)
        let centerAttribute = attributes.first(where: { attribute in
            
            // we only want to scale items, not headers or footers
            guard attribute.representedElementKind != UICollectionElementKindSectionHeader && attribute.representedElementKind != UICollectionElementKindSectionFooter else {
                return false
            }
            
            let currentItemXPosition = attribute.frame.origin.x - collectionView.contentOffset.x
            var translatedAttributeFrame = attribute.frame
            translatedAttributeFrame.origin.x = currentItemXPosition
            return translatedAttributeFrame.contains(collectionViewCenter)
        })
        
        // TODO: Add nice animation here
        centerAttribute?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        centerAttribute?.zIndex = 100
        return attributes
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        lastContentOffset = targetContentOffset(forProposedContentOffset: proposedContentOffset)
        return lastContentOffset
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else { return CGPoint.zero }
        // Find next indexPath for proposed contentOffset. Check for boundary conditions
        let nextIndexPathToFocus: IndexPath
        if lastContentOffset.x < collectionView.contentOffset.x {
            nextIndexPathToFocus = nextIndexPath
        } else if lastContentOffset.x > collectionView.contentOffset.x {
            nextIndexPathToFocus = previousIndexPath
        } else {
            nextIndexPathToFocus = focusedIndexPath
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
    
    func selectItem(at indexPath: IndexPath, animated: Bool = false) {
        focusedIndexPath = indexPath
        let contentOffset = targetContentOffset(for: indexPath)
        collectionView?.setContentOffset(contentOffset, animated: animated)
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

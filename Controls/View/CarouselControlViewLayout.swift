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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        itemSize = CGSize(width: 1, height: 1)
        scrollDirection = .horizontal
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        itemSize = CGSize(width: 150, height: 160)
        itemCount = collectionView.numberOfItems(inSection: 0)
        sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        let horizontalContentInset = collectionView.frame.width * 0.5 - itemSize.width * 0.5
        collectionView.contentInset = UIEdgeInsets(top: 0, left: horizontalContentInset, bottom: 0, right: horizontalContentInset)
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return super.collectionViewContentSize
        }

        let collectionViewHeight: CGFloat = itemSize.height + sectionInset.top + sectionInset.bottom
        let width = itemCount * Int(itemSize.width) + ((itemCount - 1) * 10)
        let collectionViewWidth = CGFloat(2 * Int(collectionView.contentInset.left) + width)
        return CGSize(width: collectionViewWidth, height: collectionViewHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }),
            let collectionView = collectionView else {
            return super.layoutAttributesForElements(in: rect)
        }

        let collectionViewCenter = CGPoint(x: collectionView.frame.width * 0.5, y: collectionView.frame.height * 0.5)
        let centerAttribute = attributes.first(where: { attribute in
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
        
        lastContentOffset = targetContentOffset(for: nextIndexPathToFocus)
        return lastContentOffset
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        lastContentOffset = targetContentOffset(for: focusedIndexPath)
        return lastContentOffset
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
            Logger.default.logError("Couldn't find a collection cell!")
            focusedIndexPath = IndexPath(row: 0, section: 0)
            return CGPoint(x: -collectionView.contentInset.left, y: collectionView.contentOffset.y)
        }
        
        let cellMinX = cell.frame.minX
        return CGPoint(x: cellMinX - collectionView.contentInset.left, y: collectionView.contentOffset.y)
    }
}

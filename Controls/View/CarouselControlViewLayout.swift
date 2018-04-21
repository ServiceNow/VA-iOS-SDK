//
//  CarouselControlViewLayout.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/28/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

protocol CarouselLayoutDelegate: AnyObject {
    func carouselLayoutHeaderHeight(_ layout: CarouselControlViewLayout) -> CGFloat
}

class CarouselControlViewLayout: UICollectionViewFlowLayout {
    
    weak var carouselDelegate: CarouselLayoutDelegate?
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
    
    private let cellSize = CGSize(width: 150, height: 160)
    private var lastContentOffset = CGPoint.zero
    private var itemCount: Int = 0
    var headerHeight: CGFloat = 0
    var footerHeight: CGFloat = 50
    
    private var supplementaryInformation = [String : UICollectionViewLayoutAttributes]()
    
    override init() {
        super.init()
        itemSize = CGSize(width: 1, height: 1)
        scrollDirection = .horizontal
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepareSupplementaryInformation() {
        guard let collectionView = collectionView else { return }
        
        supplementaryInformation.removeAll()
        let headerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: IndexPath(row: 0, section: 0))
        headerAttributes.frame = CGRect(x: 0, y: 0, width: collectionView.frame.width, height: headerHeight)
        supplementaryInformation[UICollectionElementKindSectionHeader] = headerAttributes
        
        let footerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, with: IndexPath(row: 0, section: 0))
        footerAttributes.frame = CGRect(x: 0, y: 0, width: collectionView.frame.width, height: footerHeight)
        supplementaryInformation[UICollectionElementKindSectionFooter] = footerAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        
        prepareSupplementaryInformation()
        let collectionViewHeight = collectionView.frame.height
        let itemHeight = min(cellSize.height, max(collectionViewHeight - headerHeight - footerHeight, 1))
        itemSize = CGSize(width: cellSize.width, height: itemHeight)
        itemCount = collectionView.numberOfItems(inSection: 0)
        
        let horizontalContentInset = collectionView.frame.width * 0.5 - itemSize.width * 0.5
        collectionView.contentInset = UIEdgeInsets(top: 0, left: horizontalContentInset, bottom: 0, right: horizontalContentInset)
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return super.collectionViewContentSize
        }
        
        if let height = carouselDelegate?.carouselLayoutHeaderHeight(self) {
            headerHeight = height
        }
        
        let collectionViewHeight: CGFloat = cellSize.height + footerHeight + headerHeight + 20
        let width = itemCount * Int(cellSize.width) + ((itemCount - 1) * 10)
        let collectionViewWidth = CGFloat(2 * Int(collectionView.contentInset.left) + width)
        return CGSize(width: collectionViewWidth, height: collectionViewHeight)
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView,
            let attributes = supplementaryInformation[elementKind] else {
                return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }

        var frame = attributes.frame
        frame.origin.x = collectionView.contentOffset.x
        frame.size.width = collectionView.bounds.width
        
        if elementKind == UICollectionElementKindSectionHeader {
            frame.origin.y = -collectionView.contentInset.top
            frame.size.height = headerHeight
        } else if elementKind == UICollectionElementKindSectionFooter {
            frame.origin.y = collectionView.bounds.height - footerHeight
            frame.size.height = footerHeight
        } else {
            return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }
        
        attributes.frame = frame
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }),
            let collectionView = collectionView else {
            return super.layoutAttributesForElements(in: rect)
        }
        
        let collectionViewCenter = CGPoint(x: collectionView.frame.width * 0.5, y: collectionView.frame.height * 0.5)
        let centerAttribute = attributes.first(where: { attribute in
            guard attribute.representedElementKind != UICollectionElementKindSectionHeader && attribute.representedElementKind != UICollectionElementKindSectionFooter else {
                return false
            }
            
            let currentItemXPosition = attribute.frame.origin.x - collectionView.contentOffset.x
            var translatedAttributeFrame = attribute.frame
            translatedAttributeFrame.origin.x = currentItemXPosition
            return translatedAttributeFrame.contains(collectionViewCenter)
        })
        
        attributes.forEach({ attribute in
            guard attribute.representedElementKind != UICollectionElementKindSectionHeader && attribute.representedElementKind != UICollectionElementKindSectionFooter else {
                return
            }
            
            var frame = attribute.frame
            frame.origin.y = headerHeight + 10
            attribute.frame = frame
        })
        // TODO: Add nice animation here
        centerAttribute?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        centerAttribute?.zIndex = 100
        
        // update header position
        if let calculatedHeaderAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: IndexPath(row: 0, section: 0)) {
            attributes.append(calculatedHeaderAttributes)
        }
        
        // update footer position
        if let calculatedFooterAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionFooter, at: IndexPath(row: 0, section: 0)) {
            attributes.append(calculatedFooterAttributes)
        }
        
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

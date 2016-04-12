//
//  GalleryBrowserFlowLayout.swift
//  Homehapp
//
//  Created by Lari Tuominen on 24.3.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class GalleryBrowserFlowLayout: UICollectionViewFlowLayout {
    /// Velocity threshold for a "flick" for changing a page
    private let flickVelocity: CGFloat = 0.3

    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        log.debug("contentOffset = \(collectionView!.contentOffset), proposedContentOffset = \(proposedContentOffset), velocity = \(velocity)")

        // Go through the layout attributes to find out the positioning of the cells. There is one attribute per
        // cell, so in our case, 1 or 2 at a time.
        let attributesArray = layoutAttributesForElementsInRect(collectionView!.bounds)!.filter { $0.representedElementCategory == .Cell }

        if attributesArray.count == 1 {
            // Only one cell visible; use the proposed content offset but limit it to the edges of the visible cell
            let attributes = attributesArray.first!
            let maxRight = attributes.frame.maxX - collectionView!.width
            let snapOffset = min(max(proposedContentOffset.x, attributes.frame.minX), maxRight)

            log.debug("Within large single cell; snapping to snapOffset: \(snapOffset)")

            return CGPoint(x: snapOffset, y: 0)
        }

        var maxIntersect = CGFloat.min
        var snapOffset: CGFloat = 0
        var leftmostAttributes: UICollectionViewLayoutAttributes? = nil
        var rightmostAttributes: UICollectionViewLayoutAttributes? = nil

        // Several cells visible; find where to snap
        for attributes in attributesArray {
            if leftmostAttributes == nil {
                leftmostAttributes = attributes
            }
            rightmostAttributes = attributes

            // See how much of the attributes (cell) is visible on screen. The cell which has most visible part
            // is snapped to.
            let intersect = collectionView!.bounds.intersect(attributes.frame)

            if intersect.width > maxIntersect {
                if attributes.frame.origin.x < collectionView!.bounds.origin.x {
                    // Cell is to the left; snap to its right edge
                    snapOffset = attributes.frame.maxX - collectionView!.width
                } else {
                    // Cell is to the right; snap to its left edge
                    snapOffset = attributes.frame.minX
                }

                maxIntersect = intersect.width
            }
        }

        if fabs(velocity.x) >= flickVelocity {
            // Flick gesture, change to next page
            snapOffset = (velocity.x > 0) ? rightmostAttributes!.frame.minX : leftmostAttributes!.frame.minX
            log.debug("Flicked; snapping to snapOffset: \(snapOffset)")
        }

        return CGPoint(x: snapOffset, y: 0)
    }

//    
//    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
//        
//        let rectBounds:CGRect = self.collectionView!.bounds
//        let halfHeight:CGFloat = rectBounds.size.height * CGFloat(0.45)
//        let proposedContentOffsetCenterY:CGFloat = proposedContentOffset.y + halfHeight
//        
//        let attributesArray:NSArray = self.layoutAttributesForElementsInRect(rectBounds)!
//        
//        var candidateAttributes:UICollectionViewLayoutAttributes?
//        
//        for layoutAttributes : AnyObject in attributesArray {
//            
//            if let _layoutAttributes = layoutAttributes as? UICollectionViewLayoutAttributes {
//                
//                if _layoutAttributes.representedElementCategory != UICollectionElementCategory.Cell {
//                    continue
//                }
//                
//                if candidateAttributes == nil {
//                    candidateAttributes = _layoutAttributes
//                    continue
//                }
//                
//                if fabsf(Float(_layoutAttributes.center.y) - Float(proposedContentOffsetCenterY)) < fabsf(Float(candidateAttributes!.center.y) - Float(proposedContentOffsetCenterY)) {
//                    candidateAttributes = _layoutAttributes
//                }
//            }
//        }
//        
//        if attributesArray.count == 0 {
//            return CGPointMake(proposedContentOffset.x,proposedContentOffset.y - halfHeight * 2)
//        }
//        
//        return CGPointMake(proposedContentOffset.x,candidateAttributes!.center.y - halfHeight)
//    }
}

//
//  GalleryBrowserFlowLayout.swift
//  Homehapp
//
//  Created by Lari Tuominen on 24.3.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class GalleryBrowserFlowLayout: UICollectionViewFlowLayout {
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        let rectBounds:CGRect = self.collectionView!.bounds
        let halfHeight:CGFloat = rectBounds.size.height * CGFloat(0.45)
        let proposedContentOffsetCenterY:CGFloat = proposedContentOffset.y + halfHeight
        
        let attributesArray:NSArray = self.layoutAttributesForElementsInRect(rectBounds)!
        
        var candidateAttributes:UICollectionViewLayoutAttributes?
        
        for layoutAttributes : AnyObject in attributesArray {
            
            if let _layoutAttributes = layoutAttributes as? UICollectionViewLayoutAttributes {
                
                if _layoutAttributes.representedElementCategory != UICollectionElementCategory.Cell {
                    continue
                }
                
                if candidateAttributes == nil {
                    candidateAttributes = _layoutAttributes
                    continue
                }
                
                if fabsf(Float(_layoutAttributes.center.y) - Float(proposedContentOffsetCenterY)) < fabsf(Float(candidateAttributes!.center.y) - Float(proposedContentOffsetCenterY)) {
                    candidateAttributes = _layoutAttributes
                }
            }
        }
        
        if attributesArray.count == 0 {
            return CGPointMake(proposedContentOffset.x,proposedContentOffset.y - halfHeight * 2)
        }
        
        return CGPointMake(proposedContentOffset.x,candidateAttributes!.center.y - halfHeight)
    }
}

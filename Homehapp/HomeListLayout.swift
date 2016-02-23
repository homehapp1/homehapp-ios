//
//  HomeStoryLayout.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 16/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import Foundation

/// Adds information required to track the layout
class HomeListLayoutItemAttributes: UICollectionViewLayoutAttributes {
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! HomeListLayoutItemAttributes
        return copy
    }
}

@objc protocol HomeListLayoutDelegate: UICollectionViewDelegate {
    /**
    The delegate should return the (height = aspectRatio * width) aspect ratio of the item
    at the index path. If the delegate does not implement this method, 1 is 
    used as the default value.
    */
    optional func collectionView(collectionView: UICollectionView,
        heightForItemAtIndexPath indexPath: NSIndexPath, cellWidth: CGFloat) -> CGFloat
}

/**
Provides a Pinterest-style layout for representing home stories in a collection view
in columns next to each other, with each column being able to have different size stories
stacked on top of each other instead of displaying them in a grid. For example (numbers indicate 
the order of items (indexPath.row):

normal: +-----+-----+
        |     |     |
        |  1  |     |
        +-----+  2  |
        |     |     |
        |     |     |
        |     +-----+
        |  3  |     |
        |     |  4  |
        |     |     |
        |     +-----+
        +-----+     |
        |     |     |
        |     |  5  |
        |  6  |     |
        |     +-----+
        |     |  7  |
        +-----+-----+
*/
class HomeListLayout: UICollectionViewLayout {
    /// Number of vertical columns
    private let numColumns = 2
    
    private typealias Column = (index: Int, height: CGFloat)
    
    // Current layout as a number-of-items long array of UICollectionViewLayoutAttributes objects
    private var itemAttributes = [HomeListLayoutItemAttributes]()
    
    // Columns represented with arrays of items, from top to bottom per column.
    private var columnItems = [[HomeListLayoutItemAttributes]]()
    
    // Heights for the columns
    private var columnHeights = [CGFloat]()
    
    // MARK: Private methods
    
    private func findLowestColumn() -> Column {
        var i: Int = 0
        var minValue = CGFloat.max
        
        for (index, value) in columnHeights.enumerate() {
            if value < minValue {
                i = index
                minValue = value
            }
        }
        
        return (index: i, height: minValue)
    }
    
    private func findHighestColumn() -> Column {
        var i: Int = 0
        var maxValue = CGFloat.min
        
        for (index, value) in columnHeights.enumerate() {
            if value > maxValue {
                i = index
                maxValue = value
            }
        }
        
        return (index: i, height: maxValue)
    }
    
    // MARK: From UICollectionViewLayout
    
    override class func layoutAttributesClass() -> AnyClass {
        return HomeListLayoutItemAttributes.self
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        
        columnHeights = []
        columnItems = []
        itemAttributes = []
    }
    
    override func prepareLayout() {
        // Initialize values
        columnHeights = [CGFloat](count: numColumns, repeatedValue: 0)
        columnItems = [[HomeListLayoutItemAttributes]](count: numColumns, repeatedValue: [HomeListLayoutItemAttributes]())
        itemAttributes = []
        
        let columnWidth = collectionView!.width / CGFloat(numColumns)
        let numItems = collectionView!.numberOfItemsInSection(0)
        itemAttributes.reserveCapacity(numItems)
        
        let delegate = collectionView?.delegate as? HomeListLayoutDelegate
        
        for i in 0..<numItems {
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            let cellHeight = delegate?.collectionView?(collectionView!, heightForItemAtIndexPath: indexPath, cellWidth: columnWidth) ?? 200
            
            let attrs = HomeListLayoutItemAttributes(forCellWithIndexPath: indexPath)
            
            // Form the cell's frame rectangle based on the column, column width and requested aspect ratio
            let lowestColumn = findLowestColumn()
            let x = CGFloat(lowestColumn.index) * columnWidth
            let frameRect = CGRect(x: x, y: lowestColumn.height, width: columnWidth, height: cellHeight)
            columnHeights[lowestColumn.index] += cellHeight
            columnItems[lowestColumn.index].append(attrs)

            // Add layout attributes object for this indexPath
            attrs.frame = frameRect
            itemAttributes.append(attrs)
        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Returns only those item attributes whose frame intersects with the requested frame
        return itemAttributes.filter { (attribute) -> Bool in
            return CGRectIntersectsRect(rect, attribute.frame)
        }
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return itemAttributes[indexPath.row]
    }

    override func collectionViewContentSize() -> CGSize {
        // For the content size, use collection view's width and the height of the tallest column.
        var size = collectionView!.bounds.size
        size.height = columnHeights.reduce(CGFloat.min) { max($0, $1) }

        return size
    }
}

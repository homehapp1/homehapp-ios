//
//  TextContentStoryBlockCell.swift
//  Homehapp
//
//  Created by Lari Tuominen on 31.3.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

/// Base cell for all cell having just text as content
class TextContentStoryBlockCell: BaseStoryBlockCell {

    var borderLayer: CAShapeLayer!
    var borderLayer2: CAShapeLayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor(red:0.0, green:0.0, blue:0.0, alpha:0.5).CGColor
        borderLayer.fillColor = nil
        borderLayer.lineDashPattern = [3, 3]
        borderLayer.lineWidth = 1.0
        
        borderLayer2 = CAShapeLayer()
        borderLayer2.strokeColor = UIColor(red:0.0, green:0.0, blue:0.0, alpha:0.5).CGColor
        borderLayer2.fillColor = nil
        borderLayer2.lineDashPattern = [3, 3]
        borderLayer2.lineWidth = 1.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func updateBorder(bounds: CGRect) {
        borderLayer.path = UIBezierPath(rect: bounds).CGPath
        borderLayer.frame = bounds
        borderLayer.frame.origin.y = 0
    }
    
    func updateBorder2(bounds: CGRect) {
        borderLayer2.path = UIBezierPath(rect: bounds).CGPath
        borderLayer2.frame = bounds
        borderLayer2.frame.origin.y = 0
    }
}

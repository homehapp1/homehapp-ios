//
//  UIColorExtensions.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 06/01/16.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

extension UIColor {
    
    /// homehapp main screen background pattern
    class func lightBackgroundPatternColor() -> UIColor {
        let patternImage = UIImage(named: "bg_gray-light")
        return UIColor(patternImage: patternImage!)
    }
    
    /// homehapp color for active and selected things (close to orange)
    class func homehappColorActive() -> UIColor {
        return UIColor(red: 224.0/255.0, green: 172.0/255.0, blue: 90.0/255.0, alpha: 1.0)
    }
    
    /// homehapp dark grey color for text, etc.
    class func homehappDarkColor() -> UIColor {
        return UIColor(red: 59.0/255.0, green: 48.0/255.0, blue: 49.0/255.0, alpha: 1.0)
    }

}


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

    /**
     Convenience initializer for constructing the UIColor with integer components.
     
     - parameter redInt: value for red (0-255)
     - parameter greenInt: value for green (0-255)
     - parameter blueInt: value for blue (0-255)
     - parameter alpha: value for alpha (0-1.0)
     */
    public convenience init(redInt: Int, greenInt: Int, blueInt: Int, alpha: Double) {
        self.init(red: CGFloat(redInt)/255.0, green: CGFloat(greenInt)/255.0, blue: CGFloat(blueInt)/255.0, alpha: CGFloat(alpha))
    }
    
    /**
     Convenience initializer for creating a UIColor from a hex string; accepted formats are
     RRGGBB, RRGGBBAA, #RRGGBB, #RRGGBBAA. If an invalid input is given as the hex string,
     the color is initialized to white.
     
     - parameter hexString: the RGB or RGBA string
     */
    public convenience init(hexString: String) {
        var hexString = hexString;
        
        if hexString.hasPrefix("#") {
            hexString = hexString.substring(startIndex: 1)
        }
        
        if (hexString.length != 6) && (hexString.length != 8) {
            // Color string is invalid format; return white
            self.init(white: 1.0, alpha: 1.0)
        } else {
            // If the format is RRGGBB instead of RRGGBBAA, use FF as alpha component
            if hexString.length == 6 {
                hexString = "\(hexString)FF"
            }
            
            let scanner = NSScanner(string: hexString)
            var rgbaValue: UInt32 = 0
            if scanner.scanHexInt(&rgbaValue) {
                let red = (rgbaValue & 0xFF000000) >> 24
                let green = (rgbaValue & 0x00FF0000) >> 16
                let blue = (rgbaValue & 0x0000FF00) >> 8
                let alpha = rgbaValue & 0x000000FF
                
                self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0,
                    blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha) / 255.0)
            } else {
                // Parsing the hex string failed; return white
                self.init(white: 1.0, alpha: 1.0)
            }
        }
    }
    
    public func hexColor() -> String {
        let components = CGColorGetComponents(self.CGColor)
        
        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
    }

}


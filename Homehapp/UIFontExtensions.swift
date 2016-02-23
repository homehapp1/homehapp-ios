//
//  UIFontExtensions.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/01/16.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

extension UIFont {
    
    static func roboto(size size: CGFloat) -> UIFont? {
        return UIFont(name: "Roboto-Regular", size: size)
    }
    
    static func robotoBold(size size: CGFloat) -> UIFont? {
        return UIFont(name: "Roboto-Bold", size: size)
    }
}

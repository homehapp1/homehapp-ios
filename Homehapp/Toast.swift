//
//  AppDelegate.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
Displays a toast message.
*/
class Toast: UIView {
    // Constants
    private static let animationDuration = 0.3 // The amount of time it takes the toast to appear/disappear
    private static let animationDelay = 2.0 // The amount of time the toast lingers in view

    // IBOutlets
    @IBOutlet weak var messageLabel: UILabel!

    class func show(message message: String, completionCallback: (Void -> Void)? = nil) {
        let window = UIApplication.sharedApplication().windows.last!
        let toast = NSBundle.mainBundle().loadNibNamed("Toast", owner: nil, options: nil).first as! Toast
        toast.messageLabel.text = message
        
        log.debug("Showing a toast with message: \(message)")

        var frame = toast.frame
        frame.size.width = window.width
        frame.origin.y = -frame.height
        toast.frame = frame
        window.addSubview(toast)

        // Animate toast back and forth from top of the view
        UIView.animateWithDuration(Toast.animationDuration, animations: {
            var f = toast.frame
            f.origin.y = 0
            toast.frame = f
        }) { finished in
            UIView.animateWithDuration(Toast.animationDuration, delay: Toast.animationDelay, options: .CurveEaseInOut, animations: {
                var f = toast.frame
                f.origin.y = -f.height
                toast.frame = f
                }) { finished in
                    toast.removeFromSuperview()
                    completionCallback?()
            }
        }
    }
}

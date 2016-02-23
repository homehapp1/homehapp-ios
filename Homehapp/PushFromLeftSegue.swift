//
//  PushFromLeftSegue.swift
//  Homehapp
//
//  Created by Lari Tuominen on 25.12.2015.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import QuartzCore

/// Segue that pushes destionation view controller from left to right
class PushFromLeftSegue: UIStoryboardSegue {
    
    override func perform() {
        let src: UIViewController = self.sourceViewController
        let dst: UIViewController = self.destinationViewController
        let transition: CATransition = CATransition()
        let timeFunc : CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.duration = 0.3
        transition.timingFunction = timeFunc
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        src.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
        src.navigationController!.pushViewController(dst, animated: false)
    }
    
}

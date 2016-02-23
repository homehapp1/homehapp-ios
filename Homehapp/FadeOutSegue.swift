//
//  FadeOutSegue.swift
//  Homehapp
//
//  Created by Lari Tuominen on 5.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

class FadeOutSegue: UIStoryboardSegue {
    
    override func perform() {
            let transition: CATransition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            transition.type = kCATransitionFade;
            sourceViewController.view.window?.layer.addAnimation(transition, forKey: "kCATransition")
            sourceViewController.navigationController?.popViewControllerAnimated(false)
    }
    
}

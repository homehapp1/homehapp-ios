//
//  FadeInSegue.swift
//  Homehapp
//
//  Created by Lari Tuominen on 5.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

class FadeInSegue: UIStoryboardSegue {
    
    var animated: Bool = true
    
    override func perform() {
            let transition: CATransition = CATransition()
            transition.duration = 0.3
            transition.type = kCATransitionFade;
            sourceViewController.view.window?.layer.addAnimation(transition, forKey: "kCATransition")
            sourceViewController.navigationController?.pushViewController(destinationViewController, animated: false)
        
    }
    
}
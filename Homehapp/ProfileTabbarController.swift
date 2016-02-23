//
//  ProfileTabbarController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 23.12.2015.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

class ProfileTabbarController: UITabBarController {

    let segueIdUnwindProfile = "UnwindProfile"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.hidden = true
        
        // Remove the titles and adjust the inset to account for missing title
        if let tabbarItems = self.tabBar.items {
            for tabBarItem in tabbarItems {
                tabBarItem.title = "";
                tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
            }
        }
    }
    
}
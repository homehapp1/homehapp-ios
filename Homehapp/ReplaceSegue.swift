//
//  ReplaceSegue.swift
//  Homehapp
//
//  Created by Lari Tuominen on 17.1.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import Foundation

class ReplaceSegue: UIStoryboardSegue {
    
    override func perform() {
        let navigationController: UINavigationController = sourceViewController.navigationController!;
        
        var controllerStack = navigationController.viewControllers;
        let index = controllerStack.indexOf(sourceViewController);
        controllerStack[index!] = destinationViewController
        
        navigationController.setViewControllers(controllerStack, animated: false);
    }
}
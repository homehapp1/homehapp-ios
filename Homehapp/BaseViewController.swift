//
//  BaseViewController.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/// Base class for view controllers in the project
class BaseViewController: UIViewController, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    // MARK: From UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return (navigationController!.viewControllers.count > 1)
    }
    
    // MARK: From UIViewController
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    // MARK: From UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    // MARK: Lifecycle etc

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
    }
}

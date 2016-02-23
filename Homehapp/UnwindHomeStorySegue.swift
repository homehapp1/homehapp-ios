//
//  UnwindHomeStorySegue.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 19/01/16.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

import QvikSwift
import QvikNetwork

/**
 Segue for unwinding (going 'back') home story view to homes list view; animates
 and transitions the main image element of the home story view onto the
 corresponding cell in the homes list view.
 */
class UnwindHomeStorySegue: UIStoryboardSegue {
    private let animationDuration: NSTimeInterval = 0.2

    // MARK: Private methods
    
    /// Creates a mask view for the image view for the animation
    private func createImageViewMask(imageView: CachedImageView) -> UIView {
        let maskView = UIView(frame: imageView.frame)
        maskView.translatesAutoresizingMaskIntoConstraints = true
        maskView.clipsToBounds = true
        maskView.backgroundColor = UIColor.yellowColor()
        
        maskView.addSubview(imageView)
        
        // Constrain the image view to completely fill the mask view
        let leftConstraint = NSLayoutConstraint(item: imageView, attribute: .Left, relatedBy: .Equal, toItem: maskView, attribute: .Left, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: imageView, attribute: .Right, relatedBy: .Equal, toItem: maskView, attribute: .Right, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: imageView, attribute: .Top, relatedBy: .Equal, toItem: maskView, attribute: .Top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: imageView, attribute: .Bottom, relatedBy: .Equal, toItem: maskView, attribute: .Bottom, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activateConstraints([leftConstraint, rightConstraint, topConstraint, bottomConstraint])
        
        return maskView
    }
    
    // MARK: From UIStoryboardSegue
    
    override func perform() {
        let homesController = destinationViewController as! HomesViewController
        let homeStoryController = sourceViewController as! HomeStoryViewController
        
        homesController.view.setNeedsLayout()
        homesController.view.layoutIfNeeded()
        
        guard let targetCell = homesController.cellForHome(homeStoryController.storyObject as! Home),
            sourceMainImageView = homeStoryController.headerMainImageView,
            sourceBottomView = homeStoryController.headerBottomView else {
                // This shouldnt happen since home story view was opened by clicking a cell. Log an error and pop the standard way
                log.error("Using standard pop animation.")
                sourceViewController.navigationController?.popViewControllerAnimated(true)
                return
        }

        if targetCell.isMyHomeCell {
            // Make the My Home cell update its contents as they may have changed
            targetCell.updateUI()
        }
        
        // Snapshot the homes view to be used as the background
        let homesSnapshotImageView = UIImageView(frame: homesController.view.bounds)
        homesSnapshotImageView.image = homesController.view.snapshot()
        homeStoryController.view.addSubview(homesSnapshotImageView)
        
        // Source frames
        let sourceMainImageFrame = sourceMainImageView.superview!.convertRect(sourceMainImageView.frame, toView: homeStoryController.view)
        let sourceBottomViewFrame = sourceBottomView.superview!.convertRect(sourceBottomView.frame, toView: homeStoryController.view)

        // Destination frames
        let destinationImageView = targetCell.parallaxView.parallaxContentView as! CachedImageView
        let destinationImageFrame = targetCell.parallaxView.superview!.convertRect(targetCell.parallaxView.frame, toView: homesController.view)
        let destinationBottomView = targetCell.bottomContainerView
        let destinationBottomFrame = destinationBottomView.superview!.convertRect(destinationBottomView.frame, toView: homesController.view)
        
        // Make a copy of the source image to use for animations
        let animationImageView = copyCachedImageView(sourceMainImageView)
        animationImageView.translatesAutoresizingMaskIntoConstraints = false
        let animationImageMaskView = createImageViewMask(animationImageView)
        animationImageMaskView.frame = sourceMainImageFrame
        animationImageMaskView.setNeedsLayout()
        animationImageMaskView.layoutIfNeeded()
        homeStoryController.view.addSubview(animationImageMaskView)
        
        // Make a snapshot of the source bottom container view (with home title etc) to use for animations
        let animationBottomView = UIImageView(frame: sourceBottomViewFrame)
        animationBottomView.image = sourceBottomView.snapshot()
        homeStoryController.view.addSubview(animationBottomView)
        
        // Make a snapshot of the destination bottom container view (in cell; with home title etc) to use for animations
        let animationDestinationBottomView = UIImageView(frame: animationBottomView.frame)
        animationDestinationBottomView.image = destinationBottomView.snapshot()
        animationDestinationBottomView.alpha = 0.0
        homeStoryController.view.addSubview(animationDestinationBottomView)
        
        // Make a snapshot of the homes view top bar for use in animations
        let animationTopBarView = UIImageView(frame: homesController.topBarView.bounds)
        animationTopBarView.image = homesController.topBarView.snapshot()
        animationTopBarView.transform = homesController.topBarView.transform
        homeStoryController.view.addSubview(animationTopBarView)
        
        // Animate all the pieces into place
        UIView.animateWithDuration(animationDuration, animations: {
            animationImageView.transform = destinationImageView.transform
            animationImageMaskView.frame = destinationImageFrame
            animationImageMaskView.layoutIfNeeded()
            
            animationBottomView.frame = destinationBottomFrame
            animationDestinationBottomView.frame = destinationBottomFrame
            animationDestinationBottomView.alpha = 1.0
            animationTopBarView.transform = CGAffineTransformIdentity
            }) { finished in
                // Cleanup
                homesSnapshotImageView.removeFromSuperview()
                animationImageMaskView.removeFromSuperview()
                animationBottomView.removeFromSuperview()
                animationDestinationBottomView.removeFromSuperview()
                animationTopBarView.removeFromSuperview()
                
                // Pop to the homes list view controller
                homesController.navigationController?.popViewControllerAnimated(false)
        }
    }
}

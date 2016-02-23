//
//  ShowHomeStorySegue.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 19/01/16.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

import QvikSwift
import QvikNetwork

/**
 Custom segue for opening the home story view. Animates the selected
 home into a home story.
 */
class ShowHomeStorySegue: UIStoryboardSegue {
    private let animationDuration: NSTimeInterval = 0.2
    
    /// Home cell that was tapped to start the transition
    var sourceCell: HomeCell!

    // MARK: Private methods
    
    /// Creates a mask view for the image view for the animation
    private func createImageViewMask(imageView: CachedImageView) -> UIView {
        let maskView = UIView(frame: imageView.frame)
        maskView.translatesAutoresizingMaskIntoConstraints = true
        maskView.clipsToBounds = true
        
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
        let homesController = sourceViewController as! HomesViewController
        let homeStoryController = destinationViewController as! HomeStoryViewController
        homeStoryController.view.layoutIfNeeded()

        // Source image
        let sourceParallaxView = sourceCell.parallaxView
        let sourceImageView = sourceParallaxView.parallaxContentView as! CachedImageView
        let sourceImageFrame = sourceParallaxView.superview!.convertRect(sourceParallaxView.frame, toView: homesController.view)

        // Destination image
        let destinationImageView = homeStoryController.headerMainImageView!
        let destinationImageFrame = destinationImageView.superview!.convertRect(destinationImageView.frame, toView: homeStoryController.view)
        
        // Make a copy of the source image & a mask view to be used for the animation
        let animationImageView = copyCachedImageView(sourceImageView)
        animationImageView.translatesAutoresizingMaskIntoConstraints = false
        let animationImageMaskView = createImageViewMask(animationImageView)
        animationImageMaskView.frame = sourceImageFrame
        animationImageMaskView.setNeedsLayout()
        animationImageMaskView.layoutIfNeeded()
        homesController.view.addSubview(animationImageMaskView)

        // Source bottom container (home titles etc)
        let sourceBottomView = sourceCell.bottomContainerView
        let sourceBottomFrame = sourceBottomView.superview!.convertRect(sourceBottomView.frame, toView: homesController.view)
        
        // Destination bottom container (home titles etc)
        let destinationBottomView = homeStoryController.headerBottomView!
        let destinationBottomFrame = destinationBottomView.superview!.convertRect(destinationBottomView.frame, toView: homeStoryController.view)
        
        // Make a snapshot of the destination bottom view and use it for the animation
        let animationBottomSnapshotContainerView = UIView(frame: sourceBottomFrame)
        animationBottomSnapshotContainerView.clipsToBounds = true
        let imageViewrect = CGRectMake(0, 0, sourceBottomFrame.width, sourceBottomFrame.height + 20) // TODO remove magic number 20. Needed due to the fact that we have bottom bar visible in the screen where we animate image
        let animationBottomSnapshotImageView = UIImageView(frame: imageViewrect)
        animationBottomSnapshotImageView.image = destinationBottomView.snapshot()
        animationBottomSnapshotContainerView.addSubview(animationBottomSnapshotImageView)
        homesController.view.addSubview(animationBottomSnapshotContainerView)
        
        // Animate the pieces into place
        UIView.animateWithDuration(animationDuration, animations: {

            animationImageView.transform = destinationImageView.transform
            animationImageMaskView.frame = destinationImageFrame
            animationImageMaskView.layoutIfNeeded()
            animationBottomSnapshotContainerView.frame = destinationBottomFrame
            animationBottomSnapshotImageView.frame = destinationBottomView.bounds
            
            // Hide top bar if user is viewing other's homes
            if !self.sourceCell.isMyHomeCell {
                homesController.topBarView.transform = CGAffineTransformMakeTranslation(0, -homesController.topBarView.height)
            }
            
            }) { finished in
                // Cleanup
                animationImageMaskView.removeFromSuperview()
                animationBottomSnapshotContainerView.removeFromSuperview()
                
                // Push the destination view controller (home story)
                homesController.navigationController?.pushViewController(homeStoryController, animated: false)
        }
    }
}

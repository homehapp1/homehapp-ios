//
//  OpenImageSegue.swift
//  Homehapp
//
//  Created by Tuukka Puumala on 30.10.2015.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
 Seque that opens image by zooming image towards the user.
 Unwinds image back similarly
*/
class OpenImageSegue: UIStoryboardSegue {
    private let imageMargin : CGFloat = 3
    
    /// Image to show
    var openedImageView: UIImageView?
    var currentImage: Image?
    var unwinding = false
    var backgroundImage: UIImageView?
    var blackBackgroundAlpha: CGFloat = 0.0
    
    // MARK: Private methods
    
    /// Takes a screenshot of underlying view and adds it as background view
    private func captureScreen() {
        var window: UIWindow? = UIApplication.sharedApplication().keyWindow
        window = UIApplication.sharedApplication().windows[0]
        UIGraphicsBeginImageContextWithOptions(window!.frame.size, window!.opaque, 0.0)
        window!.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let imageView = UIImageView()
        imageView.frame = (window?.frame)!
        imageView.image = image
        imageView.clipsToBounds = true
        self.backgroundImage = imageView
    }
    
    /// Creates a mask view for the image view for the animation
    private func createImageViewMask(imageView: UIImageView) -> UIView {
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
    
    /// Make a shallow copy of a UIImageView
    func copyImageView(source: UIImageView) -> UIImageView {
        let imageView = UIImageView(frame: source.frame)
        imageView.contentMode = .ScaleAspectFill
        imageView.image = source.image
        return imageView
    }
    
    override func perform() {
        let src = self.sourceViewController as UIViewController
        let dest = self.destinationViewController as UIViewController
        let belowController = self.unwinding ? dest : src
        
        // If not in portrait or face up, just use the standard pop
        if UIDevice.currentDevice().orientation != .Portrait &&
            UIDevice.currentDevice().orientation != .FaceUp {
            if unwinding {
                src.dismissViewControllerAnimated(true, completion: nil)
            } else {
                src.presentViewController(dest, animated: true, completion: nil)
            }
            return
        }
        
        // Black background
        let emptyView = UIView(frame: CGRectMake(0.0, 0.0, dest.view.width, dest.view.height))
        emptyView.alpha = self.unwinding ? blackBackgroundAlpha : 0.0
        emptyView.backgroundColor = UIColor.blackColor()
        
        // Access the app's key window and insert the destination view above the current (source) one.
        let window = UIApplication.sharedApplication().keyWindow!
        window.insertSubview(emptyView, aboveSubview: belowController.view)
        
        // Views to be animated
        var animationImageMaskView: UIView = UIView()
        var destinationImageFrame = CGRectZero
        var animationImageView: UIImageView = UIImageView()
        
        if !unwinding {
        
            // Source image
            let sourceImageFrame = openedImageView!.superview!.convertRect(openedImageView!.frame, toView: src.view)
        
            // Make a copy of the source image & a mask view to be used for the animation
            let animationImageView = copyImageView(openedImageView!)
            animationImageView.translatesAutoresizingMaskIntoConstraints = false
            animationImageMaskView = createImageViewMask(animationImageView)
            animationImageMaskView.frame = sourceImageFrame
            animationImageMaskView.setNeedsLayout()
            animationImageMaskView.layoutIfNeeded()
            window.addSubview(animationImageMaskView)
        
            // Calculate destination image frame
            let destViewAspectRatio = (dest.view.width - 2 * imageMargin) / dest.view.height
            let imageAspectRatio = openedImageView!.image!.width / openedImageView!.image!.height

            if destViewAspectRatio < imageAspectRatio {
                let width = dest.view.width - 2 * imageMargin
                let height = (width / openedImageView!.image!.width) * openedImageView!.image!.height
                destinationImageFrame = CGRectMake(imageMargin, (dest.view.height - height) / 2, width, height)
            } else {
                let height = dest.view.height
                let width = min(((height / openedImageView!.image!.height) * openedImageView!.image!.width), dest.view.width - 2 * imageMargin)
                destinationImageFrame = CGRectMake(max(imageMargin,(dest.view.width - width) / 2), (dest.view.height - height) / 2, width, height)
            }
        } else {
            
            let galleryBrowserVC = src as! GalleryBrowserViewController
            
            var sourceImageFrame = CGRectZero
            let srcViewAspectRatio = (src.view.width - 2 * imageMargin) / src.view.height
            
            let imageWidth: CGFloat = openedImageView!.image != nil ? openedImageView!.image!.width : openedImageView!.width
            let imageHeight: CGFloat = openedImageView!.image != nil ? openedImageView!.image!.height : openedImageView!.height
            let imageAspectRatio = imageWidth / imageHeight
            
            let sourceImageContainerFrame = openedImageView!.superview!.convertRect(openedImageView!.frame, toView: window)
            
            // Calculate source image frame
            if srcViewAspectRatio < imageAspectRatio {
                let width = galleryBrowserVC.isCurrentImageOpened() ? galleryBrowserVC.getSizeForOpenedImage().width : src.view.width - 2 * imageMargin

                let height = galleryBrowserVC.isCurrentImageOpened() ? min(src.view.height, imageHeight) : (width / imageWidth) * imageHeight
                let startX = sourceImageContainerFrame.x != 3 ? sourceImageContainerFrame.x : imageMargin
                sourceImageFrame = CGRectMake(startX, (src.view.height - height) / 2, width, height)
            } else {
                let height = src.view.height
                let width = min(((height / imageHeight) * imageWidth), src.view.width - 2 * imageMargin)
                let startX = sourceImageContainerFrame.x != 3 ? sourceImageContainerFrame.x : max(imageMargin,(src.view.width - width) / 2)
                sourceImageFrame = CGRectMake(startX, (src.view.height - height) / 2, width, height)
            }
            
            // Make a copy of the source image & a mask view to be used for the animation
            animationImageView = copyImageView(openedImageView!)
            animationImageView.translatesAutoresizingMaskIntoConstraints = false
            animationImageMaskView = createImageViewMask(animationImageView)
            animationImageMaskView.frame = sourceImageFrame
            animationImageMaskView.setNeedsLayout()
            animationImageMaskView.layoutIfNeeded()
            window.addSubview(animationImageMaskView)
        
            // Calculate destination frame
            if let homeVC = dest as? HomeStoryViewController {
                if let destinationFrame = homeVC.getCurrentFrameForGalleryImage(currentImage!) {
                    destinationImageFrame = destinationFrame
                }
            }
            
            if let homeInfoVC = dest as? HomeInfoViewController {
                if let destinationFrame = homeInfoVC.getCurrentFrameForGalleryImage(currentImage!) {
                    destinationImageFrame = destinationFrame
                }
            }
        }
    
        if !unwinding {
            captureScreen()
        }
        
        UIView.animateWithDuration(0.4, animations: {
            emptyView.alpha = self.unwinding ? 0.0 : 1.0
            
            animationImageMaskView.frame = destinationImageFrame
            animationImageMaskView.layoutIfNeeded()

            }) { finished in
                if self.unwinding {
                    animationImageMaskView.removeFromSuperview()
                    emptyView.removeFromSuperview()
                    self.backgroundImage?.removeFromSuperview()
                } else {
                    src.presentViewController(dest, animated: false) {
                        animationImageMaskView.removeFromSuperview()
                        emptyView.removeFromSuperview()
                        dest.view.insertSubview(self.backgroundImage!, atIndex: 0)
                    }
                    self.openedImageView?.hidden = false
                }
        }
        
        openedImageView?.hidden = true
        if self.unwinding {
            src.dismissViewControllerAnimated(false, completion: nil)
        }
    }
}

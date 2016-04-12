//
//  GalleryBrowserViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 28.10.2015.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

let segueIdUnwindHomeStoryToGalleryBrowser = "UnwindHomeStoryToGalleryBrowser"

/**
Displays story block images in horizontal browsable scrollview
*/
class GalleryBrowserViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    
    var images: [Image]? = nil
    var currentImageIndex = 0
    var selectedImage : Image?
    let scrollClosingDistance : CGFloat = 35 // Distance user bounces and this view will close
    var willClose = false
    var closingOffset : CGFloat = 0
    
    /// Indicates whether the content offset was already once set according to currentImageIndex
    private var didAdjustContentOffset = false
    
    /// Margin between images and View boundaries when image not opened / enlarged
    private let imageMargin: CGFloat = 3
    
    func isCurrentImageOpened() -> Bool {
        if selectedImage != nil {
            let cell = collectionView(self.collectionView, cellForItemAtIndexPath: NSIndexPath(forRow: currentImageIndex, inSection: 0)) as! GalleryImageCell
            if cell.width != self.view.width {
                return true
            }
        }
        return false
    }
    
    func getSizeForOpenedImage() -> CGSize {
        if selectedImage == nil {
            return CGSizeZero
        }
        
        var newSize = CGSizeMake(self.view.width, self.view.height)
        if CGFloat(selectedImage!.height) > self.view.height {
            newSize = CGSizeMake(max((self.view.height / CGFloat(selectedImage!.height)) * CGFloat(selectedImage!.width), self.view.width), self.view.height)
        } else {
            newSize = CGSizeMake(max(CGFloat(selectedImage!.width), self.view.width), max(CGFloat(selectedImage!.height), self.view.height))
        }
        return newSize
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GalleryImageCell", forIndexPath: indexPath) as! GalleryImageCell
        cell.populate(images![indexPath.row], contentMode: UIViewContentMode.ScaleAspectFit)
        if selectedImage != nil && indexPath.row == currentImageIndex {
            cell.setImageMargin(0)
        } else {
            cell.setImageMargin(imageMargin)
        }
        
        cell.deleteButton.hidden = true
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // Disable selection when gallery in landscape mode
        if self.view.width > self.view.height {
            return
        }
        
        // Select or deselect image
        if selectedImage == nil {
            selectedImage = images![indexPath.row]
        } else {
            selectedImage = nil
        }

        // Reload collectionView and set correct contentOffset
        collectionView.reloadData()
        
        if selectedImage != nil {
            let newSize = getSizeForOpenedImage()
            collectionView.setContentOffset(CGPointMake(self.collectionView.contentOffset.x + (newSize.width - self.view.width) / 2, self.collectionView.contentOffset.y), animated: false)
        } else {
            collectionView.setContentOffset(CGPointMake(CGFloat(currentImageIndex) * self.view.width, 0), animated: false)
        }
    }
    
    // Dismiss view when user bounces enough from the edges
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentSize.width > 0 &&
            (scrollView.contentOffset.x < -scrollClosingDistance || scrollView.contentOffset.x >
                scrollView.contentSize.width - scrollView.bounds.size.width + scrollClosingDistance) {
                    closeButton.enabled = false
                    performSegueWithIdentifier(segueIdUnwindHomeStoryToGalleryBrowser, sender: self)
                    self.willClose = true
                    closingOffset = scrollView.contentOffset.x
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if collectionView.visibleCells().count == 0 {
            return
        }
        
        // Stay still after closing animation started
        if willClose {
            scrollView.contentOffset.x = closingOffset
            return
        }
        
        if images!.count != 1 {
            if let indexPath = collectionView.indexPathForItemAtPoint(CGPointMake(collectionView.contentOffset.x + (self.view.width / 2), self.view.height/2)) {
                currentImageIndex = indexPath.row
            }
        }

        if scrollView.contentOffset.x < 0 || scrollView.contentSize.width - scrollView.contentOffset.x < self.view.width {
            var backgroundAlpha : CGFloat = 1.0
            if (scrollView.contentOffset.x < 0) {
                backgroundAlpha = (1.0 - abs(scrollView.contentOffset.x / self.view.frame.width))
            } else if (scrollView.contentOffset.x > 0) {
                backgroundAlpha = (1.0 - (scrollView.contentOffset.x - (scrollView.contentSize.width - self.view.width)) / self.view.width)
            }
            self.backgroundView.alpha = backgroundAlpha
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if self.selectedImage != nil && indexPath.row == currentImageIndex {
            let size = getSizeForOpenedImage()
            
            // Reset collectionview contentSize after image has been opened
            collectionView.contentSize = CGSizeMake(size.width + CGFloat(images!.count - 1) * self.view.width, collectionView.contentSize.height)
            return size
        } else {
            return CGSizeMake(self.view.width, self.view.height)
        }
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // Close opened image if currently displayed is not the one that is open
        if let _ = selectedImage where !isCurrentImageOpened() {
            self.selectedImage = nil
            collectionView.reloadData()
            log.debug("Collection view reloaded.")

            // Recalculate content offset to compensate in case a large "opened" image had offset it
            collectionView.contentOffset = CGPoint(x: collectionView.width * CGFloat(currentImageIndex), y: 0)
        }
    }

    // MARK: IBAction handlers
    
    @IBAction func closeButtonPressed(button: UIButton) {
        performSegueWithIdentifier(segueIdUnwindHomeStoryToGalleryBrowser, sender: self)
    }
    
    // MARK: From UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdUnwindHomeStoryToGalleryBrowser {
            let openImageSegue = segue as! OpenImageSegue
            let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentImageIndex, inSection: 0)) as! GalleryImageCell
            openImageSegue.openedImageView = cell.imageView
            openImageSegue.currentImage = images![currentImageIndex]
            openImageSegue.blackBackgroundAlpha = self.backgroundView.alpha
            openImageSegue.unwinding = true
            
            self.backgroundView.alpha = 0
            
            if let destViewController = segue.destinationViewController as? HomeStoryViewController {
                destViewController.hideBottomBarOriginally = false
            }
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .LandscapeLeft, .LandscapeRight]
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // Close opened image if rotation occurred
        selectedImage = nil
        
        // Get current collection view page index.
        let pageIndex = CGFloat(collectionView.indexPathForItemAtPoint(CGPointMake(collectionView.contentOffset.x, size.width / 2))!.row)
        
        // Calculate inverse transform and translationfor the background view in case we're going 
        // landscape since background view should always be portrait as the main home list view is
        let backgroudImageView = self.view.subviews[0]
        var transform = CGAffineTransformIdentity
        if size.width > size.height {
            let inverseTransform = CGAffineTransformInvert(coordinator.targetTransform())
            let translation = CGAffineTransformMakeTranslation((size.width - size.height) / 2, -(size.width - size.height) / 2)
            transform = CGAffineTransformConcat(inverseTransform, translation)
        }
        
        // Calculate content offset in the new orientation, swapping current height for width
        let contentOffsetX = collectionView.bounds.height * pageIndex

        collectionView.collectionViewLayout.invalidateLayout()
        
        coordinator.animateAlongsideTransition({ context in
            self.collectionView.contentOffset = CGPoint(x: contentOffsetX, y: 0)
            backgroudImageView.transform = transform
            }) { context in
                // Completion block
        }
    }
    
    // MARK: From UINavigationControllerDelegate
    
    override func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return [.Portrait, .LandscapeLeft, .LandscapeRight]
    }

    // MARK: Lifecycle methods
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = self.collectionView.bounds.size
       
        if !didAdjustContentOffset {
            collectionView.contentOffset = CGPointMake(CGFloat(currentImageIndex) * collectionView.bounds.size.width, 0)
            didAdjustContentOffset = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.registerNib(UINib(nibName: "GalleryImageCell", bundle: nil), forCellWithReuseIdentifier: "GalleryImageCell")
        selectedImage = nil
        collectionView.alwaysBounceHorizontal = true
        closeButton.alpha = 0
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(0.4, animations: {
            self.closeButton.alpha = 1.0
        })
    }
    
}

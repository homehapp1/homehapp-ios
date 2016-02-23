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
    
    var storyBlock: StoryBlock!
    var currentImageIndex = 0
    var selectedImage : Image?
    let scrollClosingDistance : CGFloat = 35 // Distance that user bounces and this view will close
    var willClose = false
    var closingOffset : CGFloat = 0
    
    /// Indicates whether the content offset was already once set according to currentImageIndex
    private var didAdjustContentOffset = false
    
    private let imageMargin: CGFloat = 3
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getImageCount()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GalleryImageCell", forIndexPath: indexPath) as! GalleryImageCell
        cell.populate(getStoryBlockImageAtIndex(indexPath.row), contentMode: UIViewContentMode.ScaleAspectFit)
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
        
        if selectedImage == nil {
            selectedImage = getStoryBlockImageAtIndex(indexPath.row)
        } else {
            selectedImage = nil
        }

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
        
        if getImageCount() != 1 {
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
            
            //reset collectionview contentSize after image has been opened
            collectionView.contentSize = CGSizeMake(size.width + CGFloat(getImageCount() - 1) * self.view.width, collectionView.contentSize.height)
            return size
        } else {
            return CGSizeMake(self.view.width, self.view.height)
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // Close opened image if currently displayed is not the one that is open
        if selectedImage != nil && !isCurrentImageOpened() {
            selectedImage = nil
            collectionView.reloadData()
        }
    }
    
    func isCurrentImageOpened() -> Bool {
        if selectedImage != nil {
            let cell = collectionView(self.collectionView, cellForItemAtIndexPath: NSIndexPath(forRow: currentImageIndex, inSection: 0)) as! GalleryImageCell
            if cell.width != self.view.width {
                return true
            }
        }
        return false
    }

    // MARK: IBAction handlers
    
    @IBAction func closeButtonPressed(button: UIButton) {
        performSegueWithIdentifier(segueIdUnwindHomeStoryToGalleryBrowser, sender: self)
    }
    
    // MARK: Private methods
    
    func getSizeForOpenedImage() -> CGSize {
        var newSize = CGSizeMake(self.view.width, self.view.height)
        if CGFloat(selectedImage!.height) > self.view.height {
            newSize = CGSizeMake(max((self.view.height / CGFloat(selectedImage!.height)) * CGFloat(selectedImage!.width), self.view.width), self.view.height)
        } else {
            newSize = CGSizeMake(max(CGFloat(selectedImage!.width), self.view.width), max(CGFloat(selectedImage!.height), self.view.height))
        }
        return newSize
    }
    
    /// Return image with given index
    private func getStoryBlockImageAtIndex(index: Int) -> Image {
        if storyBlock.galleryImages.count > 0 {
            return storyBlock.galleryImages[index]
        } else {
            return storyBlock.image!
        }
    }
    
    /// Return count of image we display, either gallery image count or single image
    private func getImageCount() -> Int {
        return storyBlock.galleryImages.count != 0 ? storyBlock.galleryImages.count : 1
    }
    
    // MARK: From UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdUnwindHomeStoryToGalleryBrowser {
            let openImageSegue = segue as! OpenImageSegue
            let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentImageIndex, inSection: 0)) as! GalleryImageCell
            openImageSegue.openedImageView = cell.imageView
            openImageSegue.currentImage = getStoryBlockImageAtIndex(currentImageIndex)
            openImageSegue.blackBackgroundAlpha = self.backgroundView.alpha
            self.backgroundView.alpha = 0
            openImageSegue.unwinding = true
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .LandscapeLeft, .LandscapeRight]
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // Calculate current collection view page index. First check if image is opened
        var pageIndex: CGFloat = 0
        if collectionView.contentSize.width > collectionView.bounds.width * CGFloat(getImageCount()) {
            
        } else {
            pageIndex = round(collectionView.contentOffset.x / collectionView.bounds.width)
        }
        

        // Calculate content offset in the new orientation, swapping current height for width
        let contentOffsetX = collectionView.bounds.height * pageIndex

        collectionView.collectionViewLayout.invalidateLayout()
        
        coordinator.animateAlongsideTransition({ context in
            self.collectionView.contentOffset = CGPoint(x: contentOffsetX, y: 0)
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
        self.selectedImage = nil
        self.collectionView.alwaysBounceHorizontal = true
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
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
}

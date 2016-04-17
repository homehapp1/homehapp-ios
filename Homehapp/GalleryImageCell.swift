//
//  GalleryImageCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 26/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
 Displays a single image in the gallery image grid.
*/
class GalleryImageCell: UICollectionViewCell {
    enum ImageSize {
        /// Image size for small gallery items
        case Small
        /// Image size setting for medium sized images, eg. screen-size images for lists
        case Medium
        /// Image size setting for fullscreen etc. large gallery images
        case Large
    }

    /// Image displayed in cell
    @IBOutlet weak var imageView: CachedImageView!

    /// Button to delete given image
    @IBOutlet weak var deleteButton: UIButton!
    
    /// Cell's leading and trailing constraints
    @IBOutlet private weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!
    
    /// Progress indicator for image upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!
    
    private let imageMargin: CGFloat = 3
    
    private(set) var image: Image?
    
    var deleteCallback: (Void -> Void)? {
        didSet {
            deleteButton.hidden = (deleteCallback == nil)
        }
    }
    
    // MARK: IBActions
    
    @IBAction func deleteButtonPressed(sender: UIButton) {
        log.debug("gallery image delete button pressed")
        deleteCallback?()
    }
    
    // MARK: Public methods
    
    func populate(image: Image, imageSize: ImageSize = .Large, contentMode: UIViewContentMode = UIViewContentMode.ScaleAspectFill) {
        self.image = image
        
        switch imageSize {
        case .Small:
            // Using the smallest image; no placeholder available
            imageView.placeholderImage = nil
            imageView.imageUrl = image.smallScaledUrl
        case .Medium:
            imageView.imageUrl = image.scaledUrl
            
            // Using medium image; use a smaller image as a placeholder if one is available in the in-memory cache
            if imageView.image == nil {
                imageView.placeholderImage = ImageCache.sharedInstance().getImage(url: image.smallScaledUrl, loadPolicy: .Memory)
            }
            
        case .Large:
            // Using large image; use a smaller image as a placeholder if one is available in the in-memory cache
            imageView.imageUrl = image.scaledUrl
            if imageView.image == nil {
                if let mediumImage = ImageCache.sharedInstance().getImage(url: image.mediumScaledUrl, loadPolicy: .Memory) {
                    imageView.placeholderImage = mediumImage
                } else {
                    imageView.placeholderImage = ImageCache.sharedInstance().getImage(url: image.smallScaledUrl, loadPolicy: .Memory)
                }
            }
        }
        
        if imageView.image == nil && imageView.placeholderImage == nil {
            imageView.thumbnailData = image.thumbnailData
        }
        
        imageView.fadeInColor = image.backgroundColor != nil ? UIColor(hexString: image.backgroundColor!) : UIColor.lightGrayColor()

        imageView.contentMode = contentMode
        
        if image.uploadProgress < 1.0 {
            uploadProgressView.progress = image.uploadProgress
            updateProgressBar()
        }
    }
    
    func setImageMargin(margin: CGFloat) {
        leadingConstraint.constant = margin
        trailingConstraint.constant = margin
        self.imageView.fadeInFrame = calculateFadeInImageFrame()
        self.imageView.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func toggleContentMode() {
        UIView.animateWithDuration(0.3, animations: {
            if self.leadingConstraint.constant > 0 {
                self.setImageMargin(0)
                if self.imageView.image?.height > self.height {
                    self.imageView.height = self.height
                } else {
                    self.imageView.height = self.imageView.image!.height
                    self.imageView.width = self.imageView.image!.width
                    self.imageView.center = self.center
                }
            } else {
                self.setImageMargin(self.imageMargin)
            }
        })
    }
    
    // MARK: Private methods
    
    // Calculate image frame for cachedImage fadeinView for fade in color view to be of correct size
    private func calculateFadeInImageFrame() -> CGRect {
        if let image = image {
            let imageAspectRatio = CGFloat(image.width) / CGFloat(image.height)
            let viewAspectRatio = width / height
            if imageAspectRatio >= viewAspectRatio {
                let resultWidth = min(width - 2 * imageMargin, CGFloat(image.width))
                let resultHeight = resultWidth / imageAspectRatio
                return CGRectMake(0, (height - resultHeight) / 2, resultWidth, resultHeight)
            } else {
                let resultHeight = min(height - 2 * imageMargin, CGFloat(image.height))
                let resultWidth = resultHeight * imageAspectRatio
                return CGRectMake(0, (height - resultHeight) / 2, resultWidth, resultHeight)
            }
        }
        return CGRectZero
    }
    
    private func updateProgressBar() {
        if let image = image where image.uploadProgress < 1.0 {
            uploadProgressView.hidden = false
            uploadProgressView.progress = image.uploadProgress
            runOnMainThreadAfter(delay: 0.3, task: {
                self.updateProgressBar()
            })
        } else {
            uploadProgressView.hidden = true
        }
    }

}

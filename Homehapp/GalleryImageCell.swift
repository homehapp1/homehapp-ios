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
    @IBOutlet weak var imageView: CachedImageView!

    @IBOutlet weak var deleteButton: UIButton!
    
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
    
    func populate(image: Image, contentMode: UIViewContentMode=UIViewContentMode.ScaleAspectFill) {
        self.image = image
        
        imageView.imageUrl = image.scaledUrl
        imageView.thumbnailData = image.thumbnailData
        imageView.imageFadeInDuration = 1.0
        imageView.fadeInColor = UIColor.whiteColor()
        imageView.contentMode = contentMode
        
        if image.uploadProgress < 1.0 {
            uploadProgressView.progress = image.uploadProgress
            updateProgressBar()
        }
    }
    
    func setImageMargin(margin: CGFloat) {
        leadingConstraint.constant = margin
        trailingConstraint.constant = margin
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

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
class GalleryImageCell: UICollectionViewCell, UIScrollViewDelegate {
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

    @IBOutlet private weak var scrollView: UIScrollView!

    /// Cell's leading and trailing constraints
    @IBOutlet private weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!

    /// Image height + width constraints. These are in place for the scroll view.
    @IBOutlet private weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageWidthConstraint: NSLayoutConstraint!

    /// Progress indicator for image upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!

    /// Whether pinch-zoom is active on the cell
    var enablePinchZoom = false {
        didSet {
            scrollView.delegate = enablePinchZoom ? self : nil
        }
    }

    var tappedCallback: (Void -> Void)?

    private let imageMargin: CGFloat = 3
    
    private(set) var image: Image?
    
    var deleteCallback: (Void -> Void)? {
        didSet {
            deleteButton.hidden = (deleteCallback == nil)
        }
    }
    
    // MARK: Private methods

    func tapped() {
        tappedCallback?()
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

    // MARK: Public methods
    
    func populate(image: Image, imageSize: ImageSize = .Large, contentMode: UIViewContentMode = UIViewContentMode.ScaleAspectFill) {
        self.image = image
        
        switch imageSize {
        case .Small:
            // Using the smallest image; no placeholder available
            imageView.placeholderImage = nil
            imageView.imageUrl = image.smallScaledUrl
        case .Medium:
            // Using medium image; use a smaller image as a placeholder if one is available in the in-memory cache
            imageView.placeholderImage = ImageCache.sharedInstance().getImage(url: image.smallScaledUrl, loadPolicy: .Memory)
            imageView.imageUrl = image.scaledUrl
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
            imageView.fadeInColor = image.backgroundColor != nil ? UIColor(hexString: image.backgroundColor!) : UIColor.whiteColor()
        }

        imageView.imageFadeInDuration = 0.5
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

    // MARK: IBActions

    @IBAction func deleteButtonPressed(sender: UIButton) {
        log.debug("gallery image delete button pressed")
        deleteCallback?()
    }
    
    // MARK: From UIScrollViewDelegate

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    // Lifecycle, etc.

    override func layoutSubviews() {
        super.layoutSubviews()

        log.debug("setting image size to \(width) x \(height)")
        
        imageWidthConstraint.constant = width
        imageHeightConstraint.constant = height
    }

    override func awakeFromNib() {
        super.awakeFromNib()


        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tapRecognizer)
    }
}

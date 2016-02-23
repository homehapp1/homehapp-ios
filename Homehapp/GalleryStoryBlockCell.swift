//
//  GalleryStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 20/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import QvikNetwork
import RealmSwift

/**
 Displays a list of images.
 */
class GalleryStoryBlockCell: BaseStoryBlockCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // Gallery image margin
    private static let margin: CGFloat = 3.0
    private static let maxImagesPerLine = 3

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var titleTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleBottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var addImageButton: UIButton!
    
    var titleLabelOriginalTopMarginConstraint: CGFloat = 0
    
    /// Callback that's called whenever an image is added or removed.
    var imagesChangedCallback: (Void -> Void)?
    
    /// Image selected -callback; can be used to open a full screen view
    var imageSelectedCallback: ((imageIndex: Int, imageView: UIImageView) -> Void)?
    
    let singleImageLandscapeRowHeights: [CGFloat] = [200, 240, 270]
    let singleImagePortraitRowHeights: [CGFloat] = [280, 320, 360, 390]
    let twoImageRowHeights: [CGFloat] = [150, 180, 200, 220, 240, 260]
    let threeImageRowHeights: [CGFloat] = [140, 170, 200, 230, 260]
    
    var imageSizes: [CGSize] = []
    
    var editMode = false
    
    override var deleteCallback: (Void -> Void)? {
        didSet {
            // We don't use the block-level delete button, but instead each image has its own delete button
            deleteButton?.removeFromSuperview()
            deleteButton = nil
        }
    }

    override var storyBlock: StoryBlock? {
        didSet {
            if storyBlock?.title?.length > 0 {
                titleLabel.text = storyBlock?.title?.uppercaseString
                titleBottomMarginConstraint.constant = 40;
                if removeTopMargin {
                    titleTopMarginConstraint.constant = 0;
                } else {
                    titleTopMarginConstraint.constant = 40;
                }
            } else {
                titleLabel.text = ""
                titleBottomMarginConstraint.constant = 0;
                titleTopMarginConstraint.constant = 3;
            }
            if storyBlock?.galleryImages.count > 0 {
                calculateImageSizes()
            }
            collectionView.reloadData()
        }
    }
    
    // MARK: Private methods
    
    /// Deletes one image from the gallery; if the last image is deleted, the block-level delete callback is called
    private func handleImageDeletion(image: Image) {
        if storyBlock!.galleryImages.count > 1 {
            // Find my index - we cannot use captured indexPath as its values are not necessarily correct any more
            if let myIndex = storyBlock!.galleryImages.indexOf(image) {
                // Delete selected image
                let image = storyBlock!.galleryImages[myIndex]
                
                dataManager.performUpdates {
                    image.deleted = true
                    storyBlock!.galleryImages.removeAtIndex(myIndex)
                }
                calculateImageSizes()
                imagesChangedCallback?()
                resizeCallback?()
                
                collectionView.performBatchUpdates({ [weak self] in
                    self?.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forRow: myIndex, inSection: 0)])
                    }, completion: { success in
                })
            }
        } else {
            // Delete entire block with the remaining single image
            deleteCallback?()
        }
    }
    
    /// Calculate sizes for all images in the gallery
    /// Image widths are based on widht points calculated
    /// Image sizes are stored in imageSizes variable and used when populating collectionView
    private func calculateImageSizes() {
    
        imageSizes = []
        
        // TODO remove and get collectionView width properly, not from screen!
        let bounds = UIScreen.mainScreen().bounds
        let collectionViewWidth = bounds.size.width - 2 * GalleryStoryBlockCell.margin
        
        var totalHeight: CGFloat = 0
        var imagesLeft = true
        var index = 0
        var imagesInLine = 0
        
        if let images = storyBlock?.galleryImages {
            while imagesLeft {
                
                let image = images[index]
                
                // Maximum number of images in line
                var imageAmount = defineImagesInLine(images, index: index)
                
                // lets be careful on the overflow
                if imageAmount > images.count - index {
                    imageAmount = images.count - index
                }
                
                // Two subsequent lines should not have same amount of images (if enough images left)
                if imageAmount != imagesInLine {
                    imagesInLine = imageAmount
                } else {
                    if imageAmount != 1 {
                        imagesInLine = imageAmount - 1
                    }
                }
                
                let imageRowHeight = heightForImageRow(image, imagesForLine: imagesInLine)
                totalHeight += imageRowHeight

                //Divide images for line based on proportional widths
                var widthSumForLine: CGFloat = 0
                for var i = 0; i < imagesInLine; i++ {
                    let aspectRatio = CGFloat(images[index + i].width) / CGFloat(images[index + i].height)
                    widthSumForLine += aspectRatio
                }
                
                for var j = 0; j < imagesInLine; j++ {
                    let aspectRatio = CGFloat(images[index].width) / CGFloat(images[index].height)
                    imageSizes.append(CGSizeMake(floor((collectionViewWidth - CGFloat(imagesInLine - 1) * GalleryStoryBlockCell.margin) * aspectRatio / widthSumForLine), imageRowHeight))
                    index++
                }
               
                if index >= images.count {
                    imagesLeft = false
                }
            }
        }
        
        collectionViewHeightConstraint.constant = totalHeight
    }
    
    /// Define how many images there is in line starting with image index
    private func defineImagesInLine(images: List<Image>, index: Int) -> Int {
        if let thumbnail = images[index].thumbnailData {
            var amount = thumbnail.arrayOfBytes().count % GalleryStoryBlockCell.maxImagesPerLine
            if amount == 0 {
                amount = GalleryStoryBlockCell.maxImagesPerLine
            }
            
            // If we have three images in line. we only allow one to be landscape (device is quite narrow)
            if amount == 3 && index + 2 < images.count {
                var landScapeCount = 0
                for var i = index; i < index + 3; ++i {
                    if images[i].isLandscape() {
                        ++landScapeCount
                    }
                }
                if landScapeCount > 1 {
                    amount = 2
                }
            }
            
            return amount
        }
        return Int.random(4)
    }
    
    /// Get height for image row starting with given image
    /// See widthPointsForImage method for reference
    private func heightForImageRow(image: Image, imagesForLine: Int) -> CGFloat {
        if let thumbnail = image.thumbnailData {
            let index = thumbnail.arrayOfBytes().count % 15
            if imagesForLine == 1 {
                if image.width > image.height {
                    return singleImageLandscapeRowHeights[index % singleImageLandscapeRowHeights.count]
                } else {
                    return singleImagePortraitRowHeights[index % singleImagePortraitRowHeights.count]
                }
            } else if imagesForLine == 2 {
                return twoImageRowHeights[index % twoImageRowHeights.count]
            } else {
                return threeImageRowHeights[index % threeImageRowHeights.count]
            }
        }
        return singleImageLandscapeRowHeights[Int.random(5)]
    }
    
    private func indexPathForImage(image: Image) -> NSIndexPath? {
        if let imageIndex = storyBlock?.galleryImages.indexOf(image) {
            return NSIndexPath(forRow: imageIndex, inSection: 0)
        } else {
            log.error("Image not found!")
            return nil
        }
    }
    
    // MARK: Public methods
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
        self.editMode = editMode
        
        for cell in collectionView.visibleCells() {
            if let galleryCell = cell as? GalleryImageCell {
                if editMode {
                    galleryCell.deleteCallback = { [weak self] in
                        self?.handleImageDeletion(galleryCell.image!)
                    }
                } else {
                    galleryCell.deleteCallback = nil
                }
            }
        }
        
        addImageButton.hidden = !editMode
    }
    
    /// Returns imageView of index if exists
    func imageViewForIndex(index: Int) -> UIImageView? {
        let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? GalleryImageCell
        return cell?.imageView
    }
    
    /// Returns true if this galleryBlock has given image
    func hasImage(image: Image) -> Bool {
        guard let storyBlock = storyBlock else {
            return false
        }
        
        if storyBlock.galleryImages.count > 0 {
            for blockImage in storyBlock.galleryImages {
                if image == blockImage {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Return current frame for given image
    func frameForImage(image: Image) -> CGRect {
        if let indexPath = indexPathForImage(image) {
            let layoutAttributes = collectionView.layoutAttributesForItemAtIndexPath(indexPath)
            let imageFrameInCollectionView = layoutAttributes!.frame
            let imageFrame = CGRectMake(imageFrameInCollectionView.x + GalleryStoryBlockCell.margin, imageFrameInCollectionView.y + titleBottomMarginConstraint.constant + titleTopMarginConstraint.constant + titleLabel.height, imageFrameInCollectionView.width, imageFrameInCollectionView.height)
            return imageFrame
        } else {
            return CGRectZero
        }
    }
    
    // MARK: IBAction handlers
    
    @IBAction func addImageButtonPressed(sender: UIButton) {
        addImagesCallback?(nil)
    }
    
    // MARK: From UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let storyBlock = storyBlock else {
            return 0
        }
        
        return storyBlock.galleryImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GalleryImageCell", forIndexPath: indexPath) as! GalleryImageCell

        guard let storyBlock = storyBlock else {
            return cell
        }
        
        cell.populate(storyBlock.galleryImages[indexPath.row])
        
        if editMode {
            cell.deleteCallback = { [weak self] in
                self?.handleImageDeletion(cell.image!)
            }
        } else {
            cell.deleteCallback = nil
        }
        
        return cell
    }

    // MARK: From UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! GalleryImageCell
        imageSelectedCallback?(imageIndex: indexPath.row, imageView: cell.imageView)
    }
    
    // MARK: From UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return imageSizes[indexPath.row]
    }
    
    // MARK: Lifecycle etc.
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.registerNib(UINib(nibName: "GalleryImageCell", bundle: nil), forCellWithReuseIdentifier: "GalleryImageCell")
        titleLabelOriginalTopMarginConstraint = titleTopMarginConstraint.constant
    }
    
}

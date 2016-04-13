//
//  GalleryStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 20/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import RealmSwift

/**
 Displays a list of images.
 */
class GalleryStoryBlockCell: BaseStoryBlockCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    enum GalleryType {
        case Story
        case HomeInfo
    }
    
    /// Where we are displaying this gallery
    var galleryType: GalleryType = .Story
    
    /// Gallery image margin
    private let margin: CGFloat = 3.0
    
    /// How many images are horizontally next to each other
    private let maxImagesPerLine: Int = 3

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var titleTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleBottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var addImageButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var titleLabelOriginalTopMarginConstraint: CGFloat = 0
    
    /// Image selected -callback; can be used to open a full screen view
    var imageSelectedCallback: ((imageIndex: Int, imageView: UIImageView) -> Void)?
    
    let singleImageLandscapeRowHeights: [CGFloat] = [200, 240, 270]
    let singleImagePortraitRowHeights: [CGFloat] = [280, 320, 360, 390]
    let twoImageRowHeights: [CGFloat] = [150, 180, 200, 220, 240, 260]
    let threeImageRowHeights: [CGFloat] = [140, 170, 200, 230, 260]
    
    var images: List<Image>? = nil
    var imageSizes: [CGSize] = []
    
    override var deleteCallback: (Void -> Void)? {
        didSet {
            // We don't use the block-level delete button, but instead each image has its own delete button
            deleteButton?.removeFromSuperview()
            deleteButton = nil
        }
    }
    
    override var storyBlock: StoryBlock? {
        didSet {
            if storyBlock != nil {
                show(.Story, images: storyBlock!.galleryImages, title: storyBlock!.title)
            }
        }
    }
    
    func show(galleryType: GalleryType, images: List<Image>, title: String?) {
        self.galleryType = galleryType
        self.images = images
        if let title = title where title.length > 0 {
            titleLabel.text = title
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
        if images.count > 0 {
            calculateImageSizes()
        }
        collectionView.reloadData()
    }
    
    // MARK: Private methods
    
    /// Deletes one image from the gallery; if the last image is deleted, the block-level delete callback is called
    private func handleImageDeletion(image: Image) {
        if images!.count > 1 {
            // Find my index - we cannot use captured indexPath as its values are not necessarily correct any more
            if let myIndex = images!.indexOf(image) {
                // Delete selected image
                let image = images![myIndex]
                
                dataManager.performUpdates {
                    image.deleted = true
                    if galleryType == .Story {
                        storyBlock!.galleryImages.removeAtIndex(myIndex)
                    } else {
                        appstate.mostRecentlyOpenedHome?.images.removeAtIndex(myIndex)
                    }
                }
                
                // Mark this home or neighbourhood as updated
                updateCallback?()
                
                // Delete image also from Cloudinary
                cloudStorage.removeAsset(image.url, type: "image")
                
                // Re-calculate gallery layout
                calculateImageSizes()
                resizeCallback?()
                
                //collectionView.performBatchUpdates({ [weak self] in
                    collectionView.deleteItemsAtIndexPaths([NSIndexPath(forRow: myIndex, inSection: 0)])
                //    }, completion: { success in
                //})
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
        let collectionViewWidth = bounds.size.width - 2 * margin
        
        var totalHeight: CGFloat = 0
        var imagesLeft = true
        var index = 0
        var imagesInLine = 0
        
        while imagesLeft {
                
            let image = images![index]
                
            // Maximum number of images in line
            var imageAmount = defineImagesInLine(images!, index: index)
                
            // lets be careful on the overflow
            if imageAmount > images!.count - index {
                imageAmount = images!.count - index
            }
                
            // Two subsequent lines should not have same amount of images (if enough images left)
            if imageAmount != imagesInLine {
                imagesInLine = imageAmount
            } else {
                if imageAmount != 1 {
                    imagesInLine = imageAmount - 1
                }
            }
                
            // Define row height
            let imageRowHeight = heightForImageRow(image, imagesForLine: imagesInLine)
            if totalHeight > 0 {
                totalHeight += imageRowHeight + margin
            } else {
                totalHeight += imageRowHeight
            }
                
            //Divide images for line based on proportional widths
            var widthSumForLine: CGFloat = 0
            for i in 0...imagesInLine - 1 {
                let aspectRatio = CGFloat(images![index + i].width) / CGFloat(images![index + i].height)
                widthSumForLine += aspectRatio
            }
                
            var widthUsed: CGFloat = 0
            for j in 0...imagesInLine - 1 {
                let aspectRatio = CGFloat(images![index].width) / CGFloat(images![index].height)
                if j == imagesInLine - 1 {
                    // Last image takes always all the remaining space from the line
                    let size = CGSizeMake(collectionViewWidth - widthUsed, imageRowHeight)
                    imageSizes.append(size)
                } else {
                    let size = CGSizeMake(floor((collectionViewWidth - CGFloat(imagesInLine - 1) * margin) * aspectRatio / widthSumForLine), imageRowHeight)
                    imageSizes.append(size)
                    widthUsed += size.width + margin
                }
                index += 1
            }
               
            if index >= images!.count {
                imagesLeft = false
            }
        }
        
        collectionViewHeightConstraint.constant = totalHeight
        if galleryType == .HomeInfo {
            
            // Add height constraint for content view
            let heightConstraint = NSLayoutConstraint(
                item: contentView,
                attribute: NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: nil,
                attribute: NSLayoutAttribute.NotAnAttribute,
                multiplier: 1,
                constant: totalHeight)
            
            //contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activateConstraints([heightConstraint])
            
        }
    }
    
    /// Define how many images there is in line starting with image index
    private func defineImagesInLine(images: List<Image>, index: Int) -> Int {
        
        if galleryType == .HomeInfo {
            return 3
        }
        
        var amount = 0
        if let thumbnail = images[index].thumbnailData {
            amount = thumbnail.arrayOfBytes().count % maxImagesPerLine
            if amount == 0 {
                amount = maxImagesPerLine
            }
        } else if let backgroundColor = images[index].backgroundColor where backgroundColor.length > 0 {
            let firstByte = backgroundColor[backgroundColor.startIndex.advancedBy(1)...backgroundColor.startIndex.advancedBy(2)]
            amount = Int(strtoul(firstByte, nil, 16)) % maxImagesPerLine
            if amount == 0 {
                amount = maxImagesPerLine
            }
        }
        
        // If we have three images in line. we only allow one to be landscape (device is quite narrow)
        if amount == 3 && index + 2 < images.count {
            var landScapeCount = 0
            for i in index...index + 2 {
                if images[i].isLandscape() {
                    landScapeCount += 1
                }
            }
            if landScapeCount > 1 {
                amount = 2
            }
        }
        
        return amount > 0 ? amount : Int.random(UInt32(maxImagesPerLine) + 1)
    }
    
    /// Get height for image row starting with given image
    /// See widthPointsForImage method for reference
    private func heightForImageRow(image: Image, imagesForLine: Int) -> CGFloat {
        
        if galleryType == .HomeInfo {
            return self.width / 3
        }
        
        var index = 0
        if let thumbnail = image.thumbnailData {
            index = thumbnail.arrayOfBytes().count % 15
        } else if let backgroundColor = image.backgroundColor where backgroundColor.length > 0 {
            let firstByte = backgroundColor[backgroundColor.startIndex.advancedBy(1)...backgroundColor.startIndex.advancedBy(2)]
            index = Int(strtoul(firstByte, nil, 16)) % 15
        }
        
        // Height of row is dependent on how many images there are in one line
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
    
    private func indexPathForImage(image: Image) -> NSIndexPath? {
        if let imageIndex = images!.indexOf(image) {
            return NSIndexPath(forRow: imageIndex, inSection: 0)
        } else {
            log.error("Image not found!")
            return nil
        }
    }
    
    // MARK: Public methods
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
//        self.editMode = editMode
        
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
        if images!.count > 0 {
            for blockImage in images! {
                if Image.getPublicId(image.url) == Image.getPublicId(blockImage.url) {
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
            let imageFrame = CGRectMake(imageFrameInCollectionView.x + margin, imageFrameInCollectionView.y + titleBottomMarginConstraint.constant + titleTopMarginConstraint.constant + titleLabel.height, imageFrameInCollectionView.width, imageFrameInCollectionView.height)
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
        return images!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GalleryImageCell", forIndexPath: indexPath) as! GalleryImageCell
        
        let imageSizeOption: GalleryImageCell.ImageSize
        let imageSize = imageSizes[indexPath.row]
        if imageSize.width <= Image.smallImageMaxDimensions.width && imageSize.height <= Image.smallImageMaxDimensions.height {
            imageSizeOption = .Small
        } else {
            imageSizeOption = .Medium
        }
        
        cell.populate(images![indexPath.row], imageSize: imageSizeOption)
        
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "GalleryStoryBlockCell", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! GalleryStoryBlockCell
    }
    
}

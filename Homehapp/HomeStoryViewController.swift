//
//  HomeStoryViewController.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 18/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MessageUI
import RealmSwift

import QvikSwift
import QvikNetwork

/**
 Displays the home story for a home.
 */
class HomeStoryViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {
    /// Height of the top bar, in units
    private let topBarHeight: CGFloat = 65
    
    /// Height of the bottom bar, in units
    let bottomBarHeight: CGFloat = 48
    
    /// Max amount to scroll the table view until the custom 'back' transition wont get fired any more
    private let transitionAnimationTableViewMaxScroll: CGFloat = 10
    
    let segueIdHomeStoryToGalleryBrowser = "HomeStoryToGalleryBrowser"
    private let sequeIdHomeStoryToHomeInfo = "HomeStoryToHomeInfo"
    private let segueIdUnwindHomesToHomeStory = "UnwindHomesToHomeStory"
    private let segueIdHomeStoryToNeighborhood = "HomeStoryToNeighborhood"
    private let segueIdHomeStoryToHomeSettings = "HomeStoryToHomeSettings"

    class GallerySegueData {
        let storyBlock: StoryBlock
        let imageIndex: Int
        let imageView: UIImageView
        
        init(storyBlock: StoryBlock, imageIndex: Int, imageView: UIImageView) {
            self.storyBlock = storyBlock
            self.imageIndex = imageIndex
            self.imageView = imageView
        }
    }

    /// Back button
    @IBOutlet weak var backButton: UIButton!
    
    /// Close view -button
    @IBOutlet weak var closeViewButton: UIButton!
    
    /// Button for canceling the edit state
    //@IBOutlet private weak var cancelButton: UIButton!
    
    /// Edit button; toggles to the edit mode
    @IBOutlet private weak var editButton: UIButton!
    
    /// Save button; saves all changes and toggles to the normal mode
    @IBOutlet private weak var saveButton: UIButton!
    
    /// Custom navigation bar view. Accessible from outside for use in animations.
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet private weak var topBarHeightConstraint: NSLayoutConstraint!
    
    /// 'Content' view including all view content below the custom navigation bar. Accessible from outside for use in animations.
    @IBOutlet weak var contentView: UIView!

    /// Our table view that hosts the StoryBlock cells
    @IBOutlet private weak var tableView: UITableView!

    /// Add content -controls view (in edit mode)
    @IBOutlet private weak var addControlsContainerView : UIView!
    
    /// Height constraint for the add content -controls view
    @IBOutlet private weak var addControlsContainerViewHeightConstraint: NSLayoutConstraint!
    private var addControlsContainerViewOriginalHeight: CGFloat = 0.0
    
    /// Bottom bar for changing between home story, home basic info, etc.
    @IBOutlet private weak var bottomBarView: UIView!
    private var bottomBarOriginalHeight: CGFloat = 0.0
    
    /// Height constraint for the bottom bar view
    @IBOutlet private weak var bottomBarViewHeightConstraint: NSLayoutConstraint!
    private var bottomBarViewOriginalHeight: CGFloat = 0.0
    
    /// Settings button in bottom bar which is visible only in user's own home
    @IBOutlet private weak var settingsButton: UIButton!
    
    /// Home story button in bottom bar
    @IBOutlet private weak var homeStoryButton: UIButton!
    
    /// Neighborhood button in bottom bar
    @IBOutlet private weak var neighborhoodButton: UIButton!
    
    /// Story blocks containing object being viewed, ie. Home or Neighborhood
    var storyObject: StoryObject!
    
    /// Whether edit mode is allowed
    var allowEditMode = false
    
    /// Whether the view controller is currently in edit mode
    var editMode = false
    
    /// Height of the keyboard + any text edit mode selection view, if they are showing.
    private var keyboardHeight: CGFloat? = nil
    
    /// Last scroll position for the tableview; used for hiding/showing the bottom bar
    private var tableViewScrollPosition = CGPointZero
    
    /// Last change to bottom bar height due to table view scrolling
    private var bottomBarLatestChange: CGFloat?
    
    var hideBottomBarOriginally = true
    
    var animationStarted = false
    
    /// Returns the main home image view from the header, or nil if the header is not visible (enough)
    var headerMainImageView: CachedImageView? {
        if tableView.contentOffset.y > transitionAnimationTableViewMaxScroll {
            // Table view has been scrolled too much, return nil
            return nil
        }
        
        if let headerCell = tableView.visibleCells.first as? StoryHeaderCell {
            return headerCell.mainImageView
        }
        
        return nil
    }
    
    /// Returns the bottom container (with home title etc.) for the header cell, or nil if the header is not visible (enough)
    var headerBottomView: UIView? {
        if tableView.contentOffset.y > transitionAnimationTableViewMaxScroll {
            // Table view has been scrolled too much, return nil
            return nil
        }
        
        if let headerCell = tableView.visibleCells.first as? StoryHeaderCell {
            return headerCell.bottomPartContainerView
        }
        
        return nil
    }
    
    /// Text editor selection controls view
    private let textEditModeSelectionView = TextEditorModeSelectionView()
    
    // MARK: Private methods
    
    /// Remove empty content blocks from the current story under editing
    private func removeEmptyContentBlocks() {
        for var index = storyObject.storyBlocks.count - 1; index >= 0; --index {
            let storyBlock = storyObject.storyBlocks[index]
            if storyBlock.template == StoryBlock.Template.ContentBlock.rawValue {
                if storyBlock.title == nil && storyBlock.mainText == nil ||
                    (storyBlock.title?.length == 0 && storyBlock.mainText?.length == 0)
                {
                    dataManager.performUpdates {
                        storyObject.storyBlocks.removeAtIndex(index)
                        dataManager.softDeleteStoryBlock(storyBlock)
                        storyObject.localChanges = true
                    }
                    
                    removeStoryBlockTableViewRow(index)
                }
            }
        }
    }
    
    private func toggleSettingsButtonVisibility() {
        let settingsButtonWidthConstraint = NSLayoutConstraint(item: settingsButton,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: homeStoryButton,
            attribute: .Width,
            multiplier: allowEditMode ? 1.0 : 0,
            constant: 0.0);
        self.bottomBarView.addConstraint(settingsButtonWidthConstraint);
    }
    
    private func findParentCell(forView view: UIView) -> EditableStoryCell? {
        var parent = view.superview
        
        while parent != nil {
            if let editableCell = parent as? EditableStoryCell {
                return editableCell
            }
            
            parent = parent?.superview
        }
        
        return nil
    }
    
    /// Animatedly adds a row to the table view and scrolls to the new row when done
    private func addStoryBlockTableViewRow() {
        // The new index the index of the last storyblock (we're always appending) + 1 for the header
        let newIndexPath = NSIndexPath(forRow: storyObject.storyBlocks.count, inSection: 0)
        
        CATransaction.begin()
        
        CATransaction.setCompletionBlock() {
            self.tableView.scrollToRowAtIndexPath(newIndexPath, atScrollPosition: .Bottom, animated: true)
        }
        
        tableView.beginUpdates()
        tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
        tableView.endUpdates()
        
        CATransaction.commit()
        
        dataManager.performUpdates {
            self.storyObject.localChanges = true
        }
    }
    
    /// Animatedly removes a row in the table view
    private func removeStoryBlockTableViewRow(storyBlockIndex: Int) {
        //TODO check that this index is calculated correctly; the table view seems to jump.
        
        let deletedIndexPath = NSIndexPath(forRow: storyBlockIndex + 1, inSection: 0)
        
        CATransaction.begin()
        
        CATransaction.setCompletionBlock() {
            log.debug("delete CATransaction completed")
            //TODO to avoid table view 'twitching' when deleting a row from the end of the table,
            // check here whether were past end of contentSize and smoothly scroll to the last items bottom instead.
        }
        
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths([deletedIndexPath], withRowAnimation: .Automatic)
        tableView.endUpdates()
        
        CATransaction.commit()
    }
    
    private func openImagePicker(maxSelections maxSelections: Int? = nil, editingCell: EditableStoryCell? = nil) {
        let selectController = SelectStoryblockContentTypeViewController.create()
        
        selectController.maxSelections = maxSelections
        
        if let _ = editingCell as? BigVideoStoryBlockCell {
            selectController.mediaType = .Video
        } else if let _ = editingCell as? ContentImageStoryBlockCell {
            selectController.mediaType = .Image
        }
        
        selectController.videoCallback = { [weak self] (videoAssetUrl, error) in
            assert(NSThread.isMainThread(), "Must be called on the main thread!")
            
            if let error = error {
                log.error("Video encoding failed, error: \(error)")
                Toast.show(message: NSLocalizedString("errormsg:videoenc-failed", comment: ""))
            } else {
                log.debug("Selected video with asset url: \(videoAssetUrl!)")
                self?.videoSelected(videoAssetUrl: videoAssetUrl!, editingCell: editingCell)
            }
        }
        
        selectController.imageCallback = { [weak self] (images: [UIImage], originalImageAssetUrls: [String]?) in
            assert(NSThread.isMainThread(), "Must be called on the main thread!")
            
            log.debug("selected \(images.count) images")
            self?.imagesSelected(selectedImages: images, originalURLs: originalImageAssetUrls, editingCell: editingCell)
        }
        
        navigationController!.pushViewController(selectController, animated: false)
    }
    
    /// Upload images to cloudinary and assign image objects to home
    private func imagesSelected(selectedImages selectedImages: [UIImage], originalURLs: [String]?, editingCell: EditableStoryCell?) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        var images = [Image]()
        var imageMap = [UIImage: Image]()
        
        // Insert all the selected local images into the image cache
        for selectedImage in selectedImages {
            // Create a random UUID to represent the image's 'url'
            let fakeUrl = NSUUID().UUIDString
            
            // Insert the image data into the image cache
            ImageCache.sharedInstance().putImage(image: selectedImage, url: fakeUrl, storeOnDisk: true)
            
            // Create a new Image entry with the local-only data
            let width = Int(selectedImage.width * selectedImage.scale)
            let height = Int(selectedImage.height * selectedImage.scale)
            var localUrl: String? = nil
            if originalURLs != nil {
                localUrl = originalURLs![selectedImages.indexOf(selectedImage)!]
            }

            let image = Image(url: fakeUrl, width: width, height: height, local: true, localUrl: localUrl)
            image.uploadProgress = 0.0
            
            if let snapshotThumbnailData = imageToJpegThumbnailData(sourceImage: selectedImage) {
                image.thumbnailData = snapshotThumbnailData
            }
            
            images.append(image)
            
            // Leave a mapping from the original UIImage to the Image object created
            imageMap[selectedImage] = image
        }
        
        dataManager.performUpdatesInRealm { realm in
            realm.add(images)
        }
        
        if let headerCell = editingCell as? StoryHeaderCell,
            selectedImage = selectedImages.first, image = imageMap[selectedImage] {
                // Add/changing the image of the header cell (home's main image)
                dataManager.performUpdates {
                    storyObject.image = image // Updates the cell
                    //storyObject.coverImage = image
                }
                headerCell.storyObject = storyObject
        } else if let galleryCell = editingCell as? GalleryStoryBlockCell,
            storyBlock = galleryCell.storyBlock {
                dataManager.performUpdates {
                    storyBlock.galleryImages.appendContentsOf(images)
                }
                galleryCell.storyBlock = storyBlock // Updates the cell
                tableView.reloadData()
        } else if let contentImageCell = editingCell as? ContentImageStoryBlockCell,
            selectedImage = selectedImages.first, image = imageMap[selectedImage],
            storyBlock = contentImageCell.storyBlock {
                dataManager.performUpdates {
                    storyBlock.image = image
                }
                contentImageCell.storyBlock = storyBlock
        } else {
            // Create a new StoryBlock with the local image
            dataManager.performUpdates {
                if images.count > 1 {
                    let storyBlock = StoryBlock(template: .Gallery)
                    storyBlock.galleryImages.appendContentsOf(images)
                    storyObject.storyBlocks.append(storyBlock)
                } else {
                    let storyBlock = StoryBlock(template: .ContentImage)
                    storyBlock.image = images.first
                    storyObject.storyBlocks.append(storyBlock)
                }
            }
            
            // Animatedly add the new story block row
            addStoryBlockTableViewRow()
        }
        
        for var i = 0; i < selectedImages.count; ++i {
            let selectedImage = selectedImages[i]
            
            cloudStorage.uploadImage(selectedImage, progressCallback: { (progress) -> Void in
                if let image = imageMap[selectedImage] {
                    dataManager.performUpdates {
                        image.uploadProgress = progress
                    }
                }
                }, completionCallback: { [weak self] (success: Bool, url: String?, width: Int?, height: Int?) -> Void in
                    if success {
                        // Fetch the Image object from the mapping
                        if let image = imageMap[selectedImage], url = url {
                            // Remove the original local image from the cache
                            ImageCache.sharedInstance().removeImage(url: image.url, removeFromDisk: true)
                            
                            dataManager.performUpdates {
                                // Image is now uploaded; mark it no longer local + update remote url
                                image.url = url
                                image.local = false
                                image.uploadProgress = 1.0
                            }
                            
                            dataManager.performUpdates {
                                self?.storyObject.localChanges = true
                            }
                            
                            // Start fetching the (scaled) remote images
                            ImageCache.sharedInstance().getImage(url: image.scaledUrl)
                        }
                    }
            })
        }
    }
    
    private func videoSelected(videoAssetUrl videoAssetUrl: NSURL, editingCell: EditableStoryCell?) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        guard let snapshotImage = getVideoSnapshot(videoAssetUrl) else {
            // Invalid video? show error message to user?
            log.error("Failed to extract a video snapshot image, ignoring this video.")
            return
        }
        
        // Create a Video entry from the local video asset
        let width = Int(snapshotImage.width * snapshotImage.scale)
        let height = Int(snapshotImage.height * snapshotImage.scale)
        let video = Video(url: videoAssetUrl.absoluteString, width: width, height: height, local: true)
        if let snapshotThumbnailData = imageToJpegThumbnailData(sourceImage: snapshotImage) {
            video.thumbnailData = snapshotThumbnailData
        }
        
        dataManager.performUpdatesInRealm { realm in
            realm.add(video)
        }

        log.debug("Created Video: \(video)")
        
        // Insert a thumbnail image into the image cache by that url
        ImageCache.sharedInstance().putImage(image: snapshotImage, url: videoAssetUrl.absoluteString, storeOnDisk: true)
        
        // Create a story block out of this video
        dataManager.performUpdates {
            let storyBlock = StoryBlock(template: .BigVideo)
            storyBlock.video = video
            storyObject.storyBlocks.append(storyBlock)
        }
        
        // Animatedly add the new table view row for the video
        addStoryBlockTableViewRow()
        
        // Re-encode the local video into 720p and get access to the new video file
        requestVideoDataForAssetUrl(videoAssetUrl) { (videoFileUrl, error) in
            guard let videoFilePath = videoFileUrl?.path else {
                log.error("Failed to get path for videoFileUrl: \(videoFileUrl)")
                return
            }
            log.debug("videoFilePath = \(videoFilePath)")
            
            cloudStorage.uploadVideo(videoFilePath, progressCallback: { progress in
                }, completionCallback: { (success, url, width, height) in
                    if success {
                        log.debug("Video upload successful; url: \(url)")
                        
                        // Remove the temp video file
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(videoFilePath)
                            log.debug("Temporary video file deleted.")
                        } catch let error {
                            log.error("Failed to delete temporary video file at path: \(videoFilePath), error: \(error)")
                        }
                        
                        if let url = url {
                            // Remove the local video thumbnail
                            log.debug("Removing local video url snapshot: \(video.url)")
                            ImageCache.sharedInstance().removeImage(url: video.url, removeFromDisk: true)
                            
                            // Update the video object to indicate it has been uploaded.
                            dataManager.performUpdates {
                                video.url = url
                                video.local = false
                            }
                            
                            if let thumbnailUrl = video.scaledThumbnailUrl {
                                // Start retrieving the remote video thumbnail
                                log.debug("Fetching thumbnail URL into the image cache: \(thumbnailUrl)")
                                ImageCache.sharedInstance().getImage(url: thumbnailUrl)
                            }
                        }
                    } else {
                        log.error("Video upload failed!")
                    }
            })
        }
    }
    
    /// Scroll / transform the table view so that the given text view('s bottom) is visible above the keyboard.
    private func scrollTextViewIntoView(textView: UITextView) {
        // Get the text view's frame on the visible view
        guard let textViewFrame = textView.superview?.convertRect(textView.frame, toView: view) else {
            log.error("Failed to convert text view's rect to main view coordinates")
            return
        }
        
        guard let keyboardHeight = keyboardHeight else {
            log.debug("Keyboard not visible")
            return
        }
        
        let keyboardTotalHeight = keyboardHeight + (!textEditModeSelectionView.hidden ? textEditModeSelectionView.height : 0)
        
        // Calculate the space below the text view to the bottom of the screen, compensating for the current tableview translation
        let spaceBelow = view.height - textViewFrame.maxY - (-tableView.transform.ty)
        
        // Aim to position the lower edge of the text view slightly above the top of the keyboard
        let diff = keyboardTotalHeight - spaceBelow + 10
        
        if diff <= 0 {
            // Nothing to do!
            return
        }
      
        
        // See how much of the table view's content there is left to scroll
        let leftToScroll = max(0, tableView.contentSize.height - (tableView.contentOffset.y + tableView.height))
        
        if leftToScroll > diff {
            // Well this is easy, we can simply scroll the table view up by 'diff' to completely show the text view
            var offset = tableView.contentOffset
            offset.y += diff
            tableView.setContentOffset(offset, animated: true)
            return
        } else {
            // Force the table view to its very bottom scroll offset
            let contentOffsetY = tableView.contentSize.height - tableView.bounds.height
            tableView.setContentOffset(CGPoint(x: 0, y: contentOffsetY), animated: true)
            
            let translation = keyboardTotalHeight - addControlsContainerView.height
            
            UIView.animateWithDuration(0.25) {
                self.tableView.transform = CGAffineTransformMakeTranslation(0, -translation)
            }
        }
    }
    
    private func setEditMode(editMode: Bool) {
        UIResponder.resignCurrentFirstResponder()
        
        self.editMode = editMode
        tableView.allowLongPressReordering = editMode
        editButton.hidden = editMode
        saveButton.hidden = !editMode
        //cancelButton.hidden = !editMode
        backButton.hidden = editMode
        
        // Animatedly change the edit state for visible cells
        for cell in tableView.visibleCells {
            if let editableCell = cell as? EditableStoryCell {
                editableCell.setEditMode(editMode, animated: true)
            }
        }

        editModeChanged()
    }
    
    private func toggleAddContentControls() {
        if addControlsContainerViewHeightConstraint.constant == 0 {
            // Show add content -controls, hide bottom bar
            addControlsContainerViewHeightConstraint.constant = addControlsContainerViewOriginalHeight
            bottomBarViewHeightConstraint.constant = 0
        } else {
            // Hide add content -controls, show bottom bar
            bottomBarViewHeightConstraint.constant = bottomBarViewOriginalHeight
            addControlsContainerViewHeightConstraint.constant = 0
        }
        
        self.bottomBarLatestChange = 0
        self.tableViewScrollPosition = self.tableView.contentOffset
        
        UIView.animateWithDuration(toggleEditModeAnimationDuration, animations: {
            self.view.layoutIfNeeded()
            self.bottomBarView.transform = CGAffineTransformIdentity
            }) { finished in
        }
    }
    
    /// Displays AVPlayerViewController to display full screen video
    private func playFullscreenVideo(url url: NSURL) {
        let player = AVPlayer(URL: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        self.presentViewController(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }

    // MARK: 'Protected' methods
    
    func editModeChanged() {
        tableView.beginUpdates()
        if editMode {
            // Remove home owner info cell from table view and trigger table view to resize its cells
            let homeOwnerCellIndexPath = NSIndexPath(forRow: storyObject.storyBlocks.count + 1, inSection: 0)
            tableView.deleteRowsAtIndexPaths([homeOwnerCellIndexPath], withRowAnimation: .Automatic)
        } else {
            // Add home owner info cell from table view and trigger table view to resize its cells
            let homeOwnerCellIndexPath = NSIndexPath(forRow: storyObject.storyBlocks.count + 1, inSection: 0)
            tableView.insertRowsAtIndexPaths([homeOwnerCellIndexPath], withRowAnimation: .Automatic)
        }
        tableView.endUpdates()
    }
    
    /// Maps a StoryBlock to a corresponding cell identifier
    func cellIdentifierForStoryBlock(storyBlock: StoryBlock) -> String {
        switch storyBlock.template {
        case "BigVideo":
            return "BigVideoStoryBlockCell"
        case "ContentBlock":
            return "ContentStoryBlockCell"
        case "Gallery":
            return "GalleryStoryBlockCell"
        default:
            return "ContentImageStoryBlockCell"
        }
    }
    
    /// Handles loading table view cells from their respective nibs. Override this method in inheriting classes to change behavior.
    /// Order of cells is:
    /// - header
    /// - story blocks
    /// - home owner info
    /// - [OPTIONAL] neighborhood footer
    func implTableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        let home = storyObject as! Home
        
        if indexPath.row == 0 {
            let headerCell = tableView.dequeueReusableCellWithIdentifier("StoryHeaderCell", forIndexPath: indexPath) as! StoryHeaderCell
            let navigationBarHeight: CGFloat = home.isMyHome() ? 40 : 0
            let parentSize = CGSize(width: tableView.frame.size.width, height: tableView.frame.size.height - navigationBarHeight)
            headerCell.setupGeometry(parentSize: parentSize, bottomContainerAspectRatio: appstate.homeCellBottomContainerAspectRatio, bottomBarHeight: bottomBarHeight, hasLocation: home.locationWithCity().length > 0)
            headerCell.storyObject = home
            
            cell = headerCell
        } else if indexPath.row >= (storyObject.storyBlocks.count + 1) {
            if home.userNeighborhood != nil && (indexPath.row == (home.storyBlocks.count + 2)) {
                let footerCell = tableView.dequeueReusableCellWithIdentifier("HomeStoryFooterCell", forIndexPath: indexPath) as! HomeStoryFooterCell
                footerCell.home = home

                cell = footerCell
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("HomeOwnerInfoCell", forIndexPath: indexPath)
                if let ownerCell = cell as? HomeOwnerInfoCell {
                    ownerCell.creator = home.createdBy
                    ownerCell.agent = home.agent
                    ownerCell.likeCount = home.likes
                    ownerCell.iHaveLiked = home.iHaveLiked
                    ownerCell.shareCallback = { [weak self] in
                        if let strongSelf = self {
                            let shareController = ShareController.newController(home)
                            strongSelf.presentViewController(shareController, animated: true, completion: nil)
                        }
                    }
                    ownerCell.likeCallback = {
                        dataManager.performUpdates({
                            if home.iHaveLiked {
                                home.likes = home.likes - 1
                            } else {
                                home.likes = home.likes + 1
                            }
                            home.iHaveLiked = !home.iHaveLiked
                        })
                        ownerCell.likeCount = home.likes
                        RemoteService.sharedInstance().likeHome(home, completionCallback: nil)
                    }
                    ownerCell.emailPressedCallback = { [weak self] in
                        if let strongSelf = self, email = home.agent?.email {
                            if MFMailComposeViewController.canSendMail() {
                                let mail = MFMailComposeViewController()
                                mail.mailComposeDelegate = self
                                mail.setToRecipients([email])
                                mail.setSubject("TODO, copy needed for this")
                                mail.setMessageBody("TODO, copy needed for this as well", isHTML: true)
                                strongSelf.presentViewController(mail, animated: true, completion: nil)
                            } else {
                                // TODO give feedback to the user
                            }
                        }
                    }
                }
            }
        } else {
            let storyBlock = home.storyBlocks[indexPath.row - 1]
            let cellReuseIdentifier = cellIdentifierForStoryBlock(storyBlock)
            cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
            
            if let galleryCell = cell as? GalleryStoryBlockCell {
                let storyBlock = home.storyBlocks[indexPath.row - 1]
                galleryCell.storyBlock = storyBlock
            }
        }
        
        // Top margin should be removed if cell is first cell if the story or
        // If there is two subsequent content blocks (from latter top margin is removed)
        if cell is ContentStoryBlockCell || cell is ContentImageStoryBlockCell || cell is GalleryStoryBlockCell {
            if let marginCell = cell as? BaseStoryBlockCell {
                if indexPath.row == 1 || (indexPath.row > 1 && home.storyBlocks[indexPath.row - 2].template == "ContentBlock") {
                    marginCell.removeTopMargin = true
                } else {
                    marginCell.removeTopMargin = false
                }
            }
        }
        
        assert(cell != nil, "Must have allocated a cell here")
        
        return cell!
    }
    
    // MARK: Public methods
    
    func getCurrentFrameForGalleryImage(image: Image) -> CGRect? {
        let window = UIApplication.sharedApplication().keyWindow
        for cell in tableView.visibleCells {
            
            // If image is in gallery get it's current frame
            if let galleryCell = cell as? GalleryStoryBlockCell {
                if galleryCell.hasImage(image) {
                    let imageFrameInGallery = galleryCell.frameForImage(image)
                    let galleryFrameInParentView = galleryCell.superview?.convertRect(galleryCell.frame, toView: window)
                    let frame = CGRectMake(imageFrameInGallery.origin.x + galleryFrameInParentView!.origin.x, galleryFrameInParentView!.origin.y + imageFrameInGallery.origin.y, imageFrameInGallery.width, imageFrameInGallery.height)
                    return frame
                }
            }
            
            // If image is in contentImageBlock get it's current frame
            if let contentImageCell = cell as? ContentImageStoryBlockCell {
                let imageFrame = contentImageCell.frameForImage(image)
                if imageFrame != CGRectZero {
                    let contentImageCellInParentView = contentImageCell.superview?.convertRect(contentImageCell.frame, toView: window)
                    let frame = CGRectMake(imageFrame.origin.x + contentImageCellInParentView!.origin.x, contentImageCellInParentView!.origin.y + imageFrame.origin.y, imageFrame.width, imageFrame.height)
                    return frame
                }
            }
        }
        
        return nil
    }
    
    func hideSelectedImageCell(image: Image) {
        for cell in tableView.visibleCells {
            if let galleryCell = cell as? GalleryStoryBlockCell {
                if galleryCell.hasImage(image) {
                    cell.hidden = true
                }
            }
        }
    }
    
    /// Check if there's videos playing in visible cells and pause playing if so
    func pauseAllVideos() {
        for cell in tableView.visibleCells {
            if let videoCell = cell as? BigVideoStoryBlockCell {
                videoCell.pauseVideo()
            }
        }
    }
    
    // MARK: IBAction handlers
    /*
    @IBAction func cancelButtonPressed(button: UIButton) {
        setEditMode(false)
        toggleAddContentControls()
    }
    */
    
    @IBAction func editButtonPressed(button: UIButton) {
        setEditMode(true)
        toggleAddContentControls()
    }
    
    @IBAction func saveButtonPressed(button: UIButton) {
        setEditMode(false)
        toggleAddContentControls()
        
        // Clear content blocks that have no content
        removeEmptyContentBlocks()
        
        // Attempt to send the modified info to the server
        if storyObject.localChanges {
            if storyObject is Home {
                remoteService.updateMyHomeOnServer()
            } else {
                remoteService.updateMyNeighborhood(storyObject as! Neighborhood)
            }
        }
    }
    
    @IBAction func backButtonPressed(button: UIButton) {
        UIResponder.resignCurrentFirstResponder()
        backButton.enabled = false
        performSegueWithIdentifier(segueIdUnwindHomesToHomeStory, sender: self)
    }
    
    @IBAction func addPictureButtonPressed(sender: UIButton) {
        UIResponder.resignCurrentFirstResponder()
        openImagePicker()
    }
    
    @IBAction func addTextButtonPressed(sender: UIButton) {
        UIResponder.resignCurrentFirstResponder()
        
        // Add new Content block
        dataManager.performUpdates {
            storyObject.storyBlocks.append(StoryBlock(template: .ContentBlock))
        }
        
        // Animate the addition of the new row in the table view
        addStoryBlockTableViewRow()
    }
    
    @IBAction func neighborhoodButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdHomeStoryToNeighborhood, sender: self)
    }
    
    @IBAction func settingsButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdHomeStoryToHomeSettings, sender: self)
    }
    
    @IBAction func infoButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(sequeIdHomeStoryToHomeInfo, sender: self)
    }
    
    /// Do not remove?
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {}

    // MARK: Notification handlers
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(),
            keyboardAnimationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            keyboardAnimationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt {
                // Mark the keyboard height for adjusting tableview when different text views receive first responder
                keyboardHeight = keyboardSize.height
                
                if let control = UIResponder.getCurrentFirstResponder() as? UIView,
                    parentCell = findParentCell(forView: control) where textEditModeSelectionView.hidden {
                        let modes = parentCell.supportedTextEditModes
                        if modes.count > 1 {
                            // Show text edit mode selection dialog
                            textEditModeSelectionView.setModes(modes)
                            textEditModeSelectionView.hidden = false
                            self.textEditModeSelectionView.alpha = 0.0
                            let displacement = keyboardSize.height
                            
                            let options = UIViewAnimationOptions(rawValue: keyboardAnimationCurve)
                            UIView.animateWithDuration(keyboardAnimationDuration, delay: 0, options: options, animations: { () -> Void in
                                self.textEditModeSelectionView.transform = CGAffineTransformMakeTranslation(0, -displacement)
                                self.textEditModeSelectionView.alpha = 1.0
                                }, completion: { finished in
                                    
                            })
                        }
                }
        }
        
        log.debug("Keyboard will show; keyboardHeight = \(keyboardHeight)")
    }
    
    func keyboardWillHide(notification: NSNotification) {
        keyboardHeight = 0
        
        if let keyboardAnimationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            keyboardAnimationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt {
                let options = UIViewAnimationOptions(rawValue: keyboardAnimationCurve)
                UIView.animateWithDuration(keyboardAnimationDuration, delay: 0, options: options, animations: { () -> Void in
                    log.debug("reseting tableView transform..")
                    self.tableView.transform = CGAffineTransformIdentity
                    self.textEditModeSelectionView.transform = CGAffineTransformIdentity
                    self.textEditModeSelectionView.alpha = 0.0
                    }, completion: { finished in
                        self.textEditModeSelectionView.hidden = true
                })
        }
        log.debug("Keyboard will hide")
    }
    
    func textViewEditingStarted(notification: NSNotification) {
        guard let textView = notification.object as? ExpandingTextView else {
            return
        }
        
        // Adjust the visibility + available text edit mode buttons on the textEditModeSelectionView
        if let cell = findParentCell(forView: textView) {
            let modes = cell.supportedTextEditModes
            if modes.count > 1 {
                //textEditModeSelectionView.setModes(modes)
                textEditModeSelectionView.setCurrentMode(cell.getTextEditMode())
                if textEditModeSelectionView.hidden {
                    textEditModeSelectionView.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight!)
                }
                textEditModeSelectionView.hidden = false
            } else {
                if !textEditModeSelectionView.hidden {
                }
                textEditModeSelectionView.hidden = true
            }
        }
        scrollTextViewIntoView(textView)
    }

    // MARK: From UIScrollViewDelegate
    
    // Manages the top bar visibility based on the table view scroll
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let bottomBarLatestChange = bottomBarLatestChange else {
            return
        }
        
        let translation = (bottomBarLatestChange > 0) ? bottomBarOriginalHeight : 0
        
        UIView.animateWithDuration(0.2) {
            self.bottomBarView.transform = CGAffineTransformMakeTranslation(0, translation)
        }
    }
    
    // Manages the top bar visibility based on the table view scroll
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        guard let bottomBarLatestChange = bottomBarLatestChange else {
            return
        }
        
        let translation = (bottomBarLatestChange > 0) ? bottomBarOriginalHeight : 0
        
        UIView.animateWithDuration(0.2) {
            self.bottomBarView.transform = CGAffineTransformMakeTranslation(0, translation)
        }
    }
    
    // Manages the bottom bar visibility based on the table view scroll
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let diff = scrollView.contentOffset.y - tableViewScrollPosition.y
        tableViewScrollPosition = scrollView.contentOffset
        
        if !scrollView.dragging || (scrollView.contentOffset.y <= 0) {
            return
        }

        let leftToScroll = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.height) + tableView.contentInset.bottom
        
        
        if leftToScroll < bottomBarHeight {
            // Display bottom bar when near the bottom of the table view
            let translation = min(bottomBarHeight, max(0, leftToScroll))
            bottomBarView.transform = CGAffineTransformMakeTranslation(0, translation)
            bottomBarLatestChange = nil
            return
        }
        
        // Show/hide bottom bar along the scrolling; this movement will be completed with animation when drag ends
        bottomBarLatestChange = diff / 2.0
        var translation = bottomBarView.transform.ty + bottomBarLatestChange!
        translation = max(0, min(bottomBarOriginalHeight, translation))
        bottomBarView.transform = CGAffineTransformMakeTranslation(0, translation)
    }
    
    // MARK: From UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Normal mode has header + footer; edit mode only header.
        var count = editMode ? 1 : 2

        count += storyObject.storyBlocks.count

        return count
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if editMode && ((indexPath.row) >= 1 && (indexPath.row <= storyObject.storyBlocks.count)) {
            // Can move story block cells
            return true
        } else {
            // Cannot move header / footer or if not in edit mode
            return false
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if editMode &&
            ((sourceIndexPath.row) >= 1 && (sourceIndexPath.row <= storyObject.storyBlocks.count)) &&
            ((destinationIndexPath.row) >= 1 && (destinationIndexPath.row <= storyObject.storyBlocks.count)) {
                dataManager.performUpdates {
                    let fromIndex = sourceIndexPath.row - 1
                    let toIndex = destinationIndexPath.row - 1
                    storyObject.storyBlocks.swap(fromIndex, toIndex)
                }
        } else {
            log.error("Invalid preconditions for story block move! editMode: \(editMode), sourceIndexPath: \(sourceIndexPath), destinationIndexPath: \(destinationIndexPath)")
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = implTableView(tableView, cellForRowAtIndexPath: indexPath)

        if let storyBlockCell = cell as? BaseStoryBlockCell {
            let storyBlock = storyObject.storyBlocks[indexPath.row - 1]
            storyBlockCell.storyBlock = storyBlock
            
            if let galleryCell = storyBlockCell as? GalleryStoryBlockCell {
                galleryCell.imageSelectedCallback = { [weak self] (imageIndex, imageView) in
                    if let strongSelf = self {
                        if !strongSelf.animationStarted {
                            strongSelf.animationStarted = true
                            strongSelf.performSegueWithIdentifier(strongSelf.segueIdHomeStoryToGalleryBrowser, sender: GallerySegueData(storyBlock: storyBlock, imageIndex: imageIndex, imageView: imageView))
                        }
                    }
                }
            }
            
            if let videoCell = storyBlockCell as? BigVideoStoryBlockCell {
                // video view has margins on left, right and top
                let widthMultiplier = (self.view.width - 2 * videoCell.videoViewMargin) / CGFloat(storyBlock.video!.width)
                let height = widthMultiplier * CGFloat(storyBlock.video!.height) + videoCell.videoViewMargin
                videoCell.heightConstraint.constant = height
            }
        }
        
        // Adds functionality to any editable cells
        if var editableCell = cell as? EditableStoryCell {
            editableCell.setEditMode(editMode, animated: false)
            
            editableCell.resizeCallback = { [weak self] in
                let contentOffset = tableView.contentOffset
                UIView.setAnimationsEnabled(false)
                tableView.beginUpdates()
                tableView.endUpdates()
                tableView.contentSize = tableView.sizeThatFits(CGSize(width: tableView.bounds.width, height: CGFloat.max))
                
                // Preserve content offset, but do not exceed the bottom of the tableview
                let maxOffsetY = tableView.contentSize.height - tableView.bounds.height
                let offsetY = min(maxOffsetY, contentOffset.y)
                tableView.contentOffset = CGPoint(x: 0, y: offsetY)

                UIView.setAnimationsEnabled(true)
                
                if let textView = UIResponder.getCurrentFirstResponder() as? ExpandingTextView {
                    self?.scrollTextViewIntoView(textView)
                }
            }
            
            editableCell.updateCallback = { [weak self] in
                dataManager.performUpdates {
                    self?.storyObject.localChanges = true
                }
            }
            
            editableCell.addImagesCallback = { [weak self] maxImages in
                self?.openImagePicker(maxSelections: maxImages, editingCell: editableCell)
            }
            
            if let videoCell = editableCell as? BigVideoStoryBlockCell {
                videoCell.playFullscreenCallback = { [weak self] in
                    if let videoUrl = videoCell.videoURL {
                        self?.playFullscreenVideo(url: videoUrl)
                    }
                }
            }
            
            if let contentImageCell = editableCell as? ContentImageStoryBlockCell {
                let storyBlock = storyObject.storyBlocks[indexPath.row - 1]
                if storyBlock.image != nil {
                    let widthMultiplier = (self.view.width - 2 * contentImageCell.imageMargin) / CGFloat(storyBlock.image!.width)
                    let height = widthMultiplier * CGFloat(storyBlock.image!.height) + contentImageCell.imageMargin
                    contentImageCell.imageHeightConstraint.constant = height
                } else {
                    contentImageCell.imageHeightConstraint.constant = 0
                }
                
                contentImageCell.imageSelectedCallback = { [weak self] (imageIndex, imageView) in
                    if let strongSelf = self {
                        if !strongSelf.animationStarted {
                            strongSelf.animationStarted = true
                            strongSelf.performSegueWithIdentifier(strongSelf.segueIdHomeStoryToGalleryBrowser, sender: GallerySegueData(storyBlock: storyBlock, imageIndex: imageIndex, imageView: imageView))
                        }
                    }
                }
            }
            
            if let baseCell = editableCell as? BaseStoryBlockCell {
                baseCell.deleteCallback = { [weak self] in
                    if let storyBlock = baseCell.storyBlock,
                        storyBlockIndex = self?.storyObject.storyBlocks.indexOf(storyBlock) {
                            dataManager.performUpdates {
                                self?.storyObject.storyBlocks.removeAtIndex(storyBlockIndex)
                                dataManager.softDeleteStoryBlock(storyBlock)
                                self?.storyObject.localChanges = true
                            }
                            
                            self?.removeStoryBlockTableViewRow(storyBlockIndex)
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let videoCell = cell as? BigVideoStoryBlockCell {
            videoCell.clearPlayer()
        }
    }
    
    // MARK: From UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdHomeStoryToGalleryBrowser {
            let segueData = sender as! GallerySegueData
            let galleryController = segue.destinationViewController as! GalleryBrowserViewController
            let openImageSegue = segue as! OpenImageSegue
            
            galleryController.storyBlock = segueData.storyBlock
            galleryController.currentImageIndex = segueData.imageIndex
            openImageSegue.openedImageView = segueData.imageView
        } else if segue.identifier == segueIdHomeStoryToNeighborhood {
            let homeStoryViewController = segue.destinationViewController as! HomeStoryViewController
            homeStoryViewController.hideBottomBarOriginally = false
        }
    }
    
    // MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue:
            print("Cancelled")
        case MFMailComposeResultSaved.rawValue:
            print("Saved")
        case MFMailComposeResultSent.rawValue:
            print("Sent")
        case MFMailComposeResultFailed.rawValue:
            print("Error: \(error?.localizedDescription)")
        default:
            break
        }
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Lifecycle etc.

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //image selection while we're back or first time in this screen
        animationStarted = false
        
        tableViewScrollPosition = tableView.contentOffset
        bottomBarLatestChange = 0.0

        if navigationController == nil {
            // This is being called as part of the view being added into the transition
            // animation of the custom segue; take no action
            log.debug("Not part of navigation stack, returning..")
            return
        }
        
        // Bring bottom bar into sight and close view -button visible
        closeViewButton.alpha = 0
        UIView.animateWithDuration(0.2) {
            self.bottomBarView.transform = CGAffineTransformIdentity
            self.closeViewButton.alpha = 1
        }
        
        // Enable swipe back when no navigation bar
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if storyObject == nil {
            storyObject = appstate.mostRecentlyOpenedHome
        }
        
        allowEditMode = (appstate.authUserId == appstate.mostRecentlyOpenedHome?.createdBy?.id)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 250
        
        tableView.registerNib(UINib(nibName: "HomeOwnerInfoCell", bundle: nil), forCellReuseIdentifier: "HomeOwnerInfoCell")
        tableView.registerNib(UINib(nibName: "BigVideoStoryBlockCell", bundle: nil), forCellReuseIdentifier: "BigVideoStoryBlockCell")
        tableView.registerNib(UINib(nibName: "ContentImageStoryBlockCell", bundle: nil), forCellReuseIdentifier: "ContentImageStoryBlockCell")
        tableView.registerNib(UINib(nibName: "GalleryStoryBlockCell", bundle: nil), forCellReuseIdentifier: "GalleryStoryBlockCell")
        tableView.registerNib(UINib(nibName: "HomeStoryFooterCell", bundle: nil), forCellReuseIdentifier: "HomeStoryFooterCell")
        tableView.registerNib(UINib(nibName: "StoryHeaderCell", bundle: nil), forCellReuseIdentifier: "StoryHeaderCell")
        tableView.registerNib(UINib(nibName: "ContentStoryBlockCell", bundle: nil), forCellReuseIdentifier: "ContentStoryBlockCell")

        bottomBarOriginalHeight = bottomBarViewHeightConstraint.constant
        
        // Originally hide the bottom bar
        if hideBottomBarOriginally {
            bottomBarView.transform = CGAffineTransformMakeTranslation(0, bottomBarOriginalHeight)
        }
        
        saveButton.hidden = true
        //cancelButton.hidden = true
        closeViewButton.hidden = allowEditMode
        toggleSettingsButtonVisibility()
        
        topBarHeightConstraint.constant = allowEditMode ? topBarHeight : 0.0
        
        addControlsContainerViewOriginalHeight = addControlsContainerViewHeightConstraint.constant
        bottomBarViewOriginalHeight = bottomBarViewHeightConstraint.constant
        if !editMode {
            addControlsContainerViewHeightConstraint.constant = 0
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("textViewEditingStarted:"), name: UITextViewTextDidBeginEditingNotification, object: nil)
    
        textEditModeSelectionView.hidden = true
        textEditModeSelectionView.modeSelectedCallback = { [weak self] mode in
            if let control = UIResponder.getCurrentFirstResponder() as? UIView,
                parentCell = self?.findParentCell(forView: control) {
                    parentCell.setTextEditMode(mode)
            }
        }
        view.addSubview(textEditModeSelectionView)

        // Add insets so that there is empty space on bottom of the table view to match the height of the bottom bar
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomBarHeight, right: 0)
        
        // Enable longpress -initiated drag reordering
        tableView.allowLongPressReordering = editMode
        
        // Enable neighbourhood if home has it and neighbourhood story has story blocks or story is mine
        neighborhoodButton.enabled = false
        if let openedHome = appstate.mostRecentlyOpenedHome {
            if openedHome.userNeighborhood?.storyBlocks.count > 0 || openedHome.isMyHome() {
                neighborhoodButton.enabled = true
            }
        }
      
    }
}

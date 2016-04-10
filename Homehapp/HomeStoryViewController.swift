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


/**
 Displays the home story for a home.
 */
class HomeStoryViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {
    /// Height of the top bar, in units
    private let topBarHeight: CGFloat = 65
    
    /// Width / height of the insertion cursor, in units
    private let insertionCursorSize: CGFloat = 29
    
    /// Duration (in seconds) of insertion cursor fade in/out animation
    private let insertionCursorAnimationDuration: NSTimeInterval = 0.3

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

    /// Current position (as an index to the table view) of the insertion cursor (where new block cells are inserted)
    private var insertionCursorPosition: Int? = 0
    
    /// Current insertion cursor image view 
    private var insertionCursorImageView: UIImageView!
    
    /// Height of the keyboard + any text edit mode selection view, if they are showing.
    private var keyboardHeight: CGFloat? = nil
    
    /// Last scroll position for the tableview; used for hiding/showing the bottom bar
    private var tableViewScrollPosition = CGPointZero
    
    /// Last change to bottom bar height due to table view scrolling
    private var bottomBarLatestChange: CGFloat?
    
    /// Defines if bottom bar is originally hidden and should be animated up while view appears
    var hideBottomBarOriginally = true
    
    /// Defines if image selection animation is started. Helps us to disable re-seletion during animation
    var imageSelectionAnimationStarted = false
    
    /// Should we create thumbnail data from image or not. Currently client side generation not is use
    private var createThumbnailData = false
    
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
    
    // MARK: Private methods
    
    /// Remove empty content blocks from the current story under editing
    private func removeEmptyContentBlocks() {
        for index in (storyObject.storyBlocks.count - 1).stride(through: 0, by: -1) {
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
    
    /// Calculate to which position to insert cell that will be added
    private func calculateCellInsertPosition() -> Int {
        let tableViewPoint = tableView.convertPoint(CGPointMake(self.view.width / 2, self.view.height / 3), fromView: tableView.superview)
        var newIndexPath = tableView.indexPathForRowAtPoint(tableViewPoint)
        if newIndexPath == nil {
            newIndexPath = NSIndexPath(forRow: storyObject.storyBlocks.count, inSection: 0)
        }
        
        return min(newIndexPath!.row + 1, storyObject.storyBlocks.count + 1)
    }
    
    //Animatedly adds a row to the table view
    private func addStoryBlockTableViewRow(position: Int) {
        let newIndexPath = NSIndexPath(forRow: position, inSection: 0)
        insertionCursorImageView.alpha = 0
        tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
        tableView.scrollToRowAtIndexPath(newIndexPath, atScrollPosition: .Middle, animated: true)
        
        dataManager.performUpdates {
            storyObject.localChanges = true
        }
        
        runOnMainThreadAfter(delay: 0.5, task: {
            self.manageInsertionCursor(true)
        })
    }
    
    /// Animatedly removes a row from the table view
    private func removeStoryBlockTableViewRow(storyBlockIndex: Int) {
        let deletedIndexPath = NSIndexPath(forRow: storyBlockIndex + 1, inSection: 0)
        
        insertionCursorImageView.alpha = 0
        tableView.deleteRowsAtIndexPaths([deletedIndexPath], withRowAnimation: .Automatic)
        runOnMainThreadAfter(delay: 0.5, task: {
            self.manageInsertionCursor(true)
        })
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

            let image = Image(url: fakeUrl, width: width, height: height, local: true, localUrl: localUrl, backgroundColor: selectedImage.averageColor().hexColor())
            image.uploadProgress = 0.0
            
            if createThumbnailData {
                if let snapshotThumbnailData = imageToJpegThumbnailData(sourceImage: selectedImage, dataType: thumbHeaderDataTypeIOSJPEG, compressionQuality: jpegThumbCompressionQuality, pixelBudget: jpegThumbPixelBudget) {
                    image.thumbnailData = snapshotThumbnailData
                }
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
            
            // Calculate position where to add new storyBlock
            let position = calculateCellInsertPosition()
            
            // Create a new StoryBlock with the local image
            dataManager.performUpdates {
                if images.count > 1 {
                    let storyBlock = StoryBlock(template: .Gallery)
                    storyBlock.galleryImages.appendContentsOf(images)
                    storyObject.storyBlocks.insert(storyBlock, atIndex: position - 1)
                } else {
                    let storyBlock = StoryBlock(template: .ContentImage)
                    storyBlock.image = images.first
                    storyObject.storyBlocks.insert(storyBlock, atIndex: position - 1)
                }
            }
            
            // Animatedly add the new story block row
            addStoryBlockTableViewRow(position)
        }
        
        for i in 0...selectedImages.count - 1 {
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
                            ImageCache.sharedInstance().getImage(url: image.scaledUrl, loadPolicy: .Network)
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
        video.uploadProgress = 0.0
        if createThumbnailData {
            if let snapshotThumbnailData = imageToJpegThumbnailData(sourceImage: snapshotImage, dataType: thumbHeaderDataTypeIOSJPEG, compressionQuality: jpegThumbCompressionQuality, pixelBudget: jpegThumbPixelBudget) {
                video.thumbnailData = snapshotThumbnailData
            }
        }
        
        dataManager.performUpdatesInRealm { realm in
            realm.add(video)
        }

        log.debug("Created Video: \(video)")
        
        // Insert a thumbnail image into the image cache by that url
        ImageCache.sharedInstance().putImage(image: snapshotImage, url: videoAssetUrl.absoluteString, storeOnDisk: true)
        
        // Calculate position where to add new storyBlock
        let position = calculateCellInsertPosition()
        
        // Create a story block out of this video
        dataManager.performUpdates {
            let storyBlock = StoryBlock(template: .BigVideo)
            storyBlock.video = video
            storyObject.storyBlocks.insert(storyBlock, atIndex: position - 1)
        }
        
        // Animatedly add the new table view row for the video
        addStoryBlockTableViewRow(position)
        
        // Re-encode the local video into 720p and get access to the new video file
        requestVideoDataForAssetUrl(videoAssetUrl) { (videoFileUrl, error) in
            guard let videoFilePath = videoFileUrl?.path else {
                log.error("Failed to get path for videoFileUrl: \(videoFileUrl)")
                return
            }
            log.debug("videoFilePath = \(videoFilePath)")
            
            cloudStorage.uploadVideo(videoFilePath, progressCallback: {  (progress) -> Void in
                // Video is only fully ready when comletionCallback is called
                if progress < 0.98 {
                    dataManager.performUpdates {
                        video.uploadProgress = progress
                    }
                }
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
                                video.uploadProgress = 1.00
                                self.storyObject.localChanges = true
                            }
                            
                            // Send updates to server if needed
                            remoteService.sendAllUpdatesToServer(false)
                            
                            if let thumbnailUrl = video.scaledThumbnailUrl {
                                // Start retrieving the remote video thumbnail
                                log.debug("Fetching thumbnail URL into the image cache: \(thumbnailUrl)")
                                ImageCache.sharedInstance().getImage(url: thumbnailUrl, loadPolicy: .Network)
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
        
        // Calculate the space below the text view to the bottom of the screen, compensating for the current tableview translation
        let spaceBelow = view.height - textViewFrame.maxY - (-tableView.transform.ty)
        
        // Aim to position the lower edge of the text view slightly above the top of the keyboard
        let diff = keyboardHeight - spaceBelow + 10
        
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
            
            let translation = keyboardHeight - addControlsContainerView.height
            
            UIView.animateWithDuration(0.25) {
                self.tableView.transform = CGAffineTransformMakeTranslation(0, -translation)
            }
        }
    }
    
    private func setEditMode(editMode: Bool) {
        UIResponder.resignCurrentFirstResponder()
        
        self.editMode = editMode
        tableView.allowLongPressReordering = false // Disabled for now
        editButton.hidden = editMode
        saveButton.hidden = !editMode
        backButton.hidden = editMode
        
        // Animatedly change the edit state for visible cells
        for cell in tableView.visibleCells {
            if let editableCell = cell as? EditableStoryCell {
                editableCell.setEditMode(editMode, animated: true)
            }
        }
    
        // Invalidate edit mode cursor
        insertionCursorImageView.removeFromSuperview()
        insertionCursorPosition = nil
        if editMode {
            manageInsertionCursor(false)
        }
        
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
    
    private func showTutorial(firstTutorial: TutorialType) {
        let tutorialView = TutorialView.instanceFromNib() as! TutorialView
        tutorialView.frame = view.bounds
        view.addSubview(tutorialView)
        
        if storyObject is Home {
            appstate.tutorialShown = "yes"
        } else {
            appstate.neighborhoodTutorialShown = "yes"
        }
        
        tutorialView.show(firstTutorial) { [weak self] (tutorialType) -> Void in
            if tutorialType == .EditTutorial {
                self?.editButtonPressed(self!.editButton)
            }
            if self?.storyObject is Neighborhood {
                tutorialView.tutorialType = .CloseNeighborhoodTutorial
            }
        }
    }

    /// Manages the position / visibility of the edit mode insertion cursor.
    private func manageInsertionCursor(forceRefresh: Bool) {
        
        let currentInsertCursorPosition = calculateCellInsertPosition()
        let initialInsertionCursorPosition = insertionCursorPosition
        
        if currentInsertCursorPosition != insertionCursorPosition || forceRefresh {
            insertionCursorPosition = currentInsertCursorPosition
            self.insertionCursorImageView.layer.removeAllAnimations()
            
            // Fade out current cursor
            UIView.animateWithDuration(insertionCursorAnimationDuration, animations: {
                    if initialInsertionCursorPosition != currentInsertCursorPosition {
                        self.insertionCursorImageView.alpha = 0
                    }
                }, completion: { finished in
                    if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: currentInsertCursorPosition, inSection: 0)) {
                        // Position insertion cursor in the middle of the top edge of the cell
                        let cursorOrigin = CGPoint(x: (cell.bounds.width - self.insertionCursorSize) / 2, y: cell.frame.origin.y - (self.insertionCursorSize / 2))
                        self.insertionCursorImageView.frame.origin = cursorOrigin
                        cell.superview?.addSubview(self.insertionCursorImageView)
                        
                        UIView.animateWithDuration(self.insertionCursorAnimationDuration, animations: {
                            self.insertionCursorImageView.alpha = 1
                            }, completion: { finished in
                                // No action
                        })
                    } else {
                        // cell not in sight. clear insert position so that sign is drawn when cell appears
                        self.insertionCursorPosition = 0
                    }
            })
        }
    }
    
    /// Attempt to send the modified storyObject info to the server
    private func sendStoryObjectToServer() {
        if storyObject.localChanges {
            if storyObject is Home {
                remoteService.updateMyHomeOnServer()
            } else {
                remoteService.updateMyNeighborhood(storyObject as! Neighborhood)
            }
        }
    }
    
    /// Check if there's videos playing in visible cells and stop playing if so
    private func stopAllVideos() {
        for cell in tableView.visibleCells {
            if let videoCell = cell as? BigVideoStoryBlockCell {
                videoCell.clearPlayer()
            }
        }
    }
    
    // MARK: Public Methods
    
    /// Maps a StoryBlock to a corresponding cell identifier
    func cellIdentifierForStoryBlock(storyBlock: StoryBlock) -> String {
        switch storyBlock.template {
        case "BigVideo":
            return "BigVideoStoryBlockCell"
        case "ContentBlock":
            switch storyBlock.layout {
            case .Title:
                return "ContentTitleStoryBlockCell"
            case .Body:
                return "ContentDescriptionStoryBlockCell"
            default:
                return "ContentStoryBlockCell"
            }
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
                                mail.setSubject("")
                                mail.setMessageBody("", isHTML: true)
                                strongSelf.presentViewController(mail, animated: true, completion: nil)
                            } else {
                                let url = NSURL(string: "mailto:\(email)")
                                UIApplication.sharedApplication().openURL(url!)
                            }
                        }
                    }
                }
            }
        } else {
            let storyBlock = home.storyBlocks[indexPath.row - 1]
            let cellReuseIdentifier = cellIdentifierForStoryBlock(storyBlock)
            cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        }
        
        // Top margin should be removed if cell is first cell if the story or
        // If there is two subsequent content blocks (from latter top margin is removed)
        if cell is ContentStoryBlockCell || cell is ContentImageStoryBlockCell || cell is GalleryStoryBlockCell {
            if let marginCell = cell as? BaseStoryBlockCell {
                if indexPath.row == 1 || (!home.isMyHome() && (indexPath.row > 1 && home.storyBlocks[indexPath.row - 2].template == "ContentBlock")) {
                    marginCell.removeTopMargin = true
                } else {
                    marginCell.removeTopMargin = false
                }
            }
        }
        
        assert(cell != nil, "Must have allocated a cell here")
        
        return cell!
    }
    
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
    
    /// Hide image cell that was selected during the animation start
    func hideSelectedImageCell(image: Image) {
        for cell in tableView.visibleCells {
            if let galleryCell = cell as? GalleryStoryBlockCell {
                if galleryCell.hasImage(image) {
                    cell.hidden = true
                }
            }
        }
    }
    
    @IBAction func editButtonPressed(button: UIButton) {
        setEditMode(true)
        toggleAddContentControls()
    }
    
    @IBAction func saveButtonPressed(button: UIButton) {
        setEditMode(false)
        toggleAddContentControls()
        
        // Clear content blocks that have no content
        removeEmptyContentBlocks()
        
        // Send updates to server
        sendStoryObjectToServer()
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
    
    @IBAction func addTextTitleButtonPressed(sender: UIButton) {
        addTextBlock(.Title)
    }
    
    @IBAction func addTextTitleAndBodyButtonPressed(sender: UIButton) {
        addTextBlock(.TitleAndBody)
    }
    
    @IBAction func addTextBodyButtonPressed(sender: UIButton) {
        addTextBlock(.Body)
    }
    
    private func addTextBlock(layout: StoryBlock.Layout) {
        UIResponder.resignCurrentFirstResponder()
        
        // Calculate position where to add new storyBlock
        let position = calculateCellInsertPosition()
        
        // Add new Content block
        dataManager.performUpdates {
            let storyBlock = StoryBlock(template: .ContentBlock)
            storyBlock.layout = layout
            storyObject.storyBlocks.insert(storyBlock, atIndex: position - 1)
        }
        
        // Animate the addition of the new row in the table view
        addStoryBlockTableViewRow(position)
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
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            keyboardHeight = keyboardSize.height
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
                    }, completion: { finished in
                })
        }
        log.debug("Keyboard will hide")
    }
    
    func textViewEditingStarted(notification: NSNotification) {
        guard let textView = notification.object as? ExpandingTextView else {
            return
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
        if editMode {
            // Manage the edit mode insertion cursor
            manageInsertionCursor(false)
        }
        
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
        return storyObject.storyBlocks.count + 2
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
                    if imageView.image != nil {
                        if let strongSelf = self {
                            if !strongSelf.imageSelectionAnimationStarted {
                                strongSelf.imageSelectionAnimationStarted = true
                                strongSelf.performSegueWithIdentifier(strongSelf.segueIdHomeStoryToGalleryBrowser, sender: GallerySegueData(storyBlock: storyBlock, imageIndex: imageIndex, imageView: imageView))
                            }
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
                UIView.setAnimationsEnabled(false)
                tableView.beginUpdates()
                tableView.endUpdates()
                tableView.contentSize = tableView.sizeThatFits(CGSize(width: tableView.bounds.width, height: CGFloat.max))
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
                        if !strongSelf.imageSelectionAnimationStarted {
                            strongSelf.imageSelectionAnimationStarted = true
                            strongSelf.performSegueWithIdentifier(strongSelf.segueIdHomeStoryToGalleryBrowser, sender: GallerySegueData(storyBlock: storyBlock, imageIndex: imageIndex, imageView: imageView))
                        }
                    }
                }
            }
            
            if let baseCell = editableCell as? BaseStoryBlockCell {
                baseCell.deleteCallback = { [weak self] in
                    if let storyBlock = baseCell.storyBlock,
                        storyBlockIndex = self?.storyObject.storyBlocks.indexOf(storyBlock) {
                            
                            // Remove storyBlock assets from Cloudinary
                            cloudStorage.removeAssetsFromStoryBlock(storyBlock)
                            
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
            
            if segueData.storyBlock.galleryImages.count > 0 {
                galleryController.images = Array(segueData.storyBlock.galleryImages)
            } else {
                galleryController.images = [segueData.storyBlock.image!]
            }
            
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
            log.debug("Cancelled")
        case MFMailComposeResultSaved.rawValue:
            log.debug("Saved")
        case MFMailComposeResultSent.rawValue:
            log.debug("Sent")
        case MFMailComposeResultFailed.rawValue:
            log.debug("Error: \(error?.localizedDescription)")
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
    
    override func viewWillDisappear(animated: Bool) {
        stopAllVideos()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        imageSelectionAnimationStarted = false
        
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
            if self.hideBottomBarOriginally {
                self.bottomBarView.transform = CGAffineTransformIdentity
            }
            self.closeViewButton.alpha = 1
        }
        
        // Enable swipe back when no navigation bar
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        // Show tutorial if it is not shown yet and user opens her own home
        if storyObject is Home && appstate.tutorialShown == nil && allowEditMode && storyObject.storyBlocks.count == 0 {
            showTutorial(.WelcomeTutorial)
        }
        
        // Show edit tutorial in neighborhood story if not shown yet
        if storyObject is Neighborhood && appstate.neighborhoodTutorialShown == nil && allowEditMode && storyObject.storyBlocks.count == 0 {
            showTutorial(.EditTutorial)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        // Preload user neighbourhood cover image
        if let neightborhoodCoverImageURL = appstate.mostRecentlyOpenedHome?.userNeighborhood?.image?.scaledUrl {
            if neightborhoodCoverImageURL != "" && !ImageCache.sharedInstance().availableInMemory(url:neightborhoodCoverImageURL) {
                ImageCache.sharedInstance().getImage(url: neightborhoodCoverImageURL, loadPolicy: .Network)
            }
        }
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
        tableView.estimatedRowHeight = 80
        
        tableView.registerNib(UINib(nibName: "HomeOwnerInfoCell", bundle: nil), forCellReuseIdentifier: "HomeOwnerInfoCell")
        tableView.registerNib(UINib(nibName: "BigVideoStoryBlockCell", bundle: nil), forCellReuseIdentifier: "BigVideoStoryBlockCell")
        tableView.registerNib(UINib(nibName: "ContentImageStoryBlockCell", bundle: nil), forCellReuseIdentifier: "ContentImageStoryBlockCell")
        tableView.registerNib(UINib(nibName: "GalleryStoryBlockCell", bundle: nil), forCellReuseIdentifier: "GalleryStoryBlockCell")
        tableView.registerNib(UINib(nibName: "HomeStoryFooterCell", bundle: nil), forCellReuseIdentifier: "HomeStoryFooterCell")
        tableView.registerNib(UINib(nibName: "StoryHeaderCell", bundle: nil), forCellReuseIdentifier: "StoryHeaderCell")
        tableView.registerNib(UINib(nibName: "ContentStoryBlockCell", bundle: nil), forCellReuseIdentifier: "ContentStoryBlockCell")
        tableView.registerNib(UINib(nibName: "ContentTitleStoryBlockCell", bundle: nil), forCellReuseIdentifier: "ContentTitleStoryBlockCell")
        tableView.registerNib(UINib(nibName: "ContentDescriptionStoryBlockCell", bundle: nil), forCellReuseIdentifier: "ContentDescriptionStoryBlockCell")
        
        
        bottomBarOriginalHeight = bottomBarViewHeightConstraint.constant
        
        // Originally hide the bottom bar
        if hideBottomBarOriginally {
            bottomBarView.transform = CGAffineTransformMakeTranslation(0, bottomBarOriginalHeight)
        }
        
        saveButton.hidden = true
        closeViewButton.hidden = allowEditMode
        toggleSettingsButtonVisibility()
        
        topBarHeightConstraint.constant = allowEditMode ? topBarHeight : 0.0
        
        addControlsContainerViewOriginalHeight = addControlsContainerViewHeightConstraint.constant
        bottomBarViewOriginalHeight = bottomBarViewHeightConstraint.constant
        if !editMode {
            addControlsContainerViewHeightConstraint.constant = 0
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeStoryViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeStoryViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeStoryViewController.textViewEditingStarted(_:)), name: UITextViewTextDidBeginEditingNotification, object: nil)

        insertionCursorImageView = UIImageView(image: UIImage(named: "icon_add_here"))
        insertionCursorImageView.frame = CGRect(x: 0, y: 0, width: insertionCursorSize, height: insertionCursorSize)

        // Add insets so that there is empty space on bottom of the table view to match the height of the bottom bar
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomBarHeight, right: 0)
        
        // Enable or disable longpress -initiated drag reordering
        tableView.allowLongPressReordering = false
        
        // Enable neighbourhood if home has it and neighbourhood story has story blocks or story is mine
        neighborhoodButton.enabled = false
        if let openedHome = appstate.mostRecentlyOpenedHome {
            if openedHome.userNeighborhood?.storyBlocks.count > 0 || openedHome.isMyHome() {
                neighborhoodButton.enabled = true
            }
        }
       
    }
}

//
//  NeighborhoodViewController.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 26/01/16.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit
import RealmSwift

/**
 Displays a Neighborhood story and provides an edit mode.
*/
class NeighborhoodViewController: HomeStoryViewController {
    private let segueIdNeighborhoodToHomeStory = "NeighborhoodToHomeStory"
    private let segueIdNeighborhoodToHomeSettings = "NeighborhoodToHomeSettings"
    private let segueIdNeighborhoodToHomeInfo = "NeighborhoodToHomeInfo"
    
    // MARK: Overridden methods
    
    // Hide back button when editing
    override func editModeChanged() {
        if editMode {
            backButton.hidden = true
        } else {
            backButton.hidden = false
        }
    }
    
    /// Handles loading table view cells from their respective nibs. Override this method in inheriting classes to change behavior.
    /// Order of cells is:
    /// - header
    /// - story blocks
    override func implTableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if indexPath.row == 0 {
            let headerCell = tableView.dequeueReusableCellWithIdentifier("StoryHeaderCell", forIndexPath: indexPath) as! StoryHeaderCell
            
            headerCell.setupGeometry(parentSize: tableView.frame.size, bottomContainerAspectRatio: 0.4, bottomBarHeight: bottomBarHeight, hasLocation: appstate.mostRecentlyOpenedHome!.locationWithCity().length > 0)
            
            headerCell.storyObject = storyObject
            
            cell = headerCell
        } else {
            let storyBlock = storyObject.storyBlocks[indexPath.row - 1]
            let cellReuseIdentifier = cellIdentifierForStoryBlock(storyBlock)
            cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
            
            /*
            if let galleryCell = cell as? GalleryStoryBlockCell {
                let storyBlock = storyObject.storyBlocks[indexPath.row - 1]
                galleryCell.storyBlock = storyBlock
            }
            */
        }
        
        assert(cell != nil, "Must have allocated a cell here")
        
        return cell!
    }
    
    // MARK: IBAction handlers
    
    @IBAction func homeStoryButtonPressed(button: UIButton) {
        performSegueWithIdentifier(segueIdNeighborhoodToHomeStory, sender: self)
    }
    
    @IBAction override func settingsButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdNeighborhoodToHomeSettings, sender: self)
    }
    
    @IBAction override func infoButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdNeighborhoodToHomeInfo, sender: self)
    }
    
    @IBAction override func backButtonPressed(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: From UITableViewDataSource

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if editMode && (indexPath.row >= 1) {
            // Can move story block cells
            return true
        } else {
            // Cannot move header or footer or if not in edit mode
            return false
        }
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if editMode && (sourceIndexPath.row >= 1) && (destinationIndexPath.row >= 1) {
            dataManager.performUpdates {
                let fromIndex = sourceIndexPath.row - 1
                let toIndex = destinationIndexPath.row - 1
                storyObject.storyBlocks.swap(fromIndex, toIndex)
            }
        } else {
            log.error("Invalid preconditions for story block move! editMode: \(editMode), sourceIndexPath: \(sourceIndexPath), destinationIndexPath: \(destinationIndexPath)")
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Header + story blocks
        return storyObject.storyBlocks.count + 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
       if segue.identifier == segueIdNeighborhoodToHomeStory {
            let homeStoryViewController = segue.destinationViewController as! HomeStoryViewController
            homeStoryViewController.hideBottomBarOriginally = false
       } else if segue.identifier == segueIdHomeStoryToGalleryBrowser {
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
        }
    }
    
    // MARK: Lifecycle etc
    
    override func viewDidLoad() {
        super.viewDidLoad()

        storyObject = appstate.mostRecentlyOpenedHome!.userNeighborhood!
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
}


//
//  HomeInfoViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 30.1.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

/**
 Displays home information that user can edit
*/ 
class HomeInfoViewController: BaseViewController, UIScrollViewDelegate {

    /// Vertical stack view that holds all the content in this view
    @IBOutlet weak var stackView: UIStackView!
    
    /// Action buttons for back, edit, save and close
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var editButton: UIButton!
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    
    /// Bottom bar for changing between home story, home basic info, etc.
    @IBOutlet private weak var bottomBarView: UIView!
    
    /// Top bar should only be shown for users own home
    @IBOutlet private weak var topBarView: UIView!
    
    /// Height constraint for top bar
    @IBOutlet private weak var topBarHeightConstraint: NSLayoutConstraint!
    
    /// Settings button in bottom bar which is visible only in user's own home
    @IBOutlet private weak var settingsButton: UIButton!
    
    /// Home story button in bottom bar
    @IBOutlet private weak var homeStoryButton: UIButton!
    
    /// Home story button in bottom bar
    @IBOutlet private weak var neighborhoodButton: UIButton!
    
    /// StackView and all the content is inside this view
    @IBOutlet private weak var scrollView: UIScrollView!
    
    /// Height constraint for the bottom bar view
    @IBOutlet private weak var bottomBarViewHeightConstraint: NSLayoutConstraint!
    
    /// Defines if this view is in edit mode or not
    var editMode: Bool = false
    
    private let segueIdHomeInfoToHomeStory = "HomeInfoToHomeStory"
    private let segueIdHomeInfoToHomeSettings = "HomeInfoToHomeSettings"
    private let segueIdHomeInfoToNeighborhood = "HomeInfoToNeighborhood"
    private let segueIdHomeInfoToAddHomeLocation = "HomeInfoToAddHomeLocation"
    private let segueIdHomeInfoToAddHomeFeatures = "HomeInfoToAddHomeFeatures"
    
    /// Height of the bottom bar, in units
    let bottomBarHeight: CGFloat = 48
    
    /// Last scroll position for the tableview; used for hiding/showing the bottom bar
    private var tableViewScrollPosition = CGPointZero
    
    /// Last change to bottom bar height due to table view scrolling
    private var bottomBarLatestChange: CGFloat?
    private var bottomBarOriginalHeight: CGFloat = 0.0
    
    // MARK: IBActions
    
    @IBAction func settingsButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdHomeInfoToHomeSettings, sender: self)
    }
    
    @IBAction func storyButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdHomeInfoToHomeStory, sender: self)
    }
    
    @IBAction func neighborhoodButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdHomeInfoToNeighborhood, sender: self)
    }
    
    @IBAction func editButtonPressed(sender: UIButton) {
        backButton.hidden = true
        saveButton.hidden = false
        editButton.hidden = true
        editMode = true
        for view in stackView.subviews {
            if let editableView = view as? EditableHomeInfoView {
                editableView.setEditMode(true, animated: false)
            }
        }
    }
    
    @IBAction func saveButtonPressed(sender: UIButton) {
        backButton.hidden = false
        saveButton.hidden = true
        editButton.hidden = false
        editMode = false
        
        setSubviewEditModes()
    }
    
    @IBAction func backButtonPressed(button: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: Private methods
    
    /// Set editmode on or off for all the stackview subviews
    private func setSubviewEditModes() {
        for view in stackView.subviews {
            if let editableView = view as? EditableHomeInfoView {
                editableView.setEditMode(editMode, animated: false)
            }
        }
    }
    
    /// Set setting visible if invisible and vice verca
    private func toggleSettingsButtonVisibility() {
        let settingsButtonWidthConstraint = NSLayoutConstraint(item: settingsButton,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: homeStoryButton,
            attribute: .Width,
            multiplier: appstate.mostRecentlyOpenedHome!.createdBy?.id == appstate.authUserId ? 1.0 : 0,
            constant: 0.0);
        self.bottomBarView.addConstraint(settingsButtonWidthConstraint);
    }
    
    /// Header section
    private func addHeaderView() {
        let headerView = HomeInfoHeaderView.instanceFromNib() as! HomeInfoHeaderView
        stackView.addArrangedSubview(headerView)
    }
    
    /// Rooms section
    private func addRoomsView() {
        let homeRoomsView = HomeRoomsView.instanceFromNib() as! HomeRoomsView
        stackView.addArrangedSubview(homeRoomsView)
        homeRoomsView.home = appstate.mostRecentlyOpenedHome!
    }
    
    /// Home Description section
    private func addDescriptionView() {
        let home = appstate.mostRecentlyOpenedHome!
        if home.isMyHome() || (!home.isMyHome() && home.homeDescription.length > 0) {
            let homeDescriptionView = HomeDescriptionView.instanceFromNib() as! HomeDescriptionView
            stackView.addArrangedSubview(homeDescriptionView)
            homeDescriptionView.home = appstate.mostRecentlyOpenedHome!
        }
    }
    
    /// Home Features section
    private func addFeaturesView() {
        let home = appstate.mostRecentlyOpenedHome!
        if home.isMyHome() || (!home.isMyHome() && home.getFeatures().count > 0) {
            let homeFeaturesView = HomeFeaturesView.instanceFromNib() as! HomeFeaturesView
            stackView.addArrangedSubview(homeFeaturesView)
            homeFeaturesView.home = appstate.mostRecentlyOpenedHome!
            homeFeaturesView.editFeaturesCallback = { [weak self] in
                if home.isMyHome() {
                    self?.performSegueWithIdentifier((self?.segueIdHomeInfoToAddHomeFeatures)!, sender: self)
                }
            }
        }
    }
    
    /// Map section
    private func addMapSection() {
        let homeMapView = HomeMapView.instanceFromNib() as! HomeMapView
        stackView.addArrangedSubview(homeMapView)
        homeMapView.home = appstate.mostRecentlyOpenedHome!
        homeMapView.addLocationcallback = { [weak self] in
            self?.performSegueWithIdentifier((self?.segueIdHomeInfoToAddHomeLocation)!, sender: self)
        }
    }
    
    // MARK: ScrollView delegate
    
    // Manages the bottom bar visibility based on the table view scroll
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let diff = scrollView.contentOffset.y - tableViewScrollPosition.y
        tableViewScrollPosition = scrollView.contentOffset
        
        if !scrollView.dragging || (scrollView.contentOffset.y <= 0) {
            return
        }
        
        let leftToScroll = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.height) + scrollView.contentInset.bottom
        
        
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
    
    // MARK: Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !editMode {
            saveButton.hidden = true
        }
        
        if appstate.mostRecentlyOpenedHome!.createdBy?.id != appstate.authUserId {
            topBarHeightConstraint.constant = 0
            closeButton.hidden = false
        }
        
        toggleSettingsButtonVisibility()
        
        for subview in stackView.arrangedSubviews {
            subview.removeFromSuperview()
            stackView.removeArrangedSubview(subview)
        }
        
        addHeaderView()
        addRoomsView()
        addDescriptionView()
        addFeaturesView()
        addMapSection()
        
        neighborhoodButton.enabled = false
        if let openedHome = appstate.mostRecentlyOpenedHome {
            if openedHome.userNeighborhood?.storyBlocks.count > 0 || openedHome.isMyHome() {
                neighborhoodButton.enabled = true
            }
        }
        
        setSubviewEditModes()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomBarOriginalHeight = bottomBarViewHeightConstraint.constant
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdHomeInfoToHomeStory || segue.identifier == segueIdHomeInfoToNeighborhood {
            let homeStoryViewController = segue.destinationViewController as! HomeStoryViewController
            homeStoryViewController.hideBottomBarOriginally = false
        }
    }
    
}

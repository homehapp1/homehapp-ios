//
//  HomeInfoViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 30.1.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit
import RealmSwift

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
    @IBOutlet weak var bottomBarView: UIView!
    
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
    private let segueIdHomeInfoToHomeInfoImage = "HomeInfoToHomeInfoImage"
    private let segueIdHomeInfoToGalleryBrowser = "HomeInfoToGalleryBrowser"
    
    /// Height of the bottom bar, in units
    let bottomBarHeight: CGFloat = 48
    
    /// Last scroll position for the tableview; used for hiding/showing the bottom bar
    private var tableViewScrollPosition = CGPointZero
    
    /// Last change to bottom bar height due to table view scrolling
    private var bottomBarLatestChange: CGFloat?
    private var bottomBarOriginalHeight: CGFloat = 0.0
    
    // Image Picker for EPC and floorplan
    var imagePicker = UIImagePickerController()
    var pickingMode: ImagePickingMode = .EPC
    
    /// Defines if image selection animation is started. Helps us to disable re-seletion during animation
    var imageSelectionAnimationStarted = false
    
    // MARK: IBActions
    
    @IBAction func settingsButtonPressed(sender: UIButton) {
        if editMode {
            saveButtonPressed(saveButton)
        }
        performSegueWithIdentifier(segueIdHomeInfoToHomeSettings, sender: self)
    }
    
    @IBAction func storyButtonPressed(sender: UIButton) {
        if editMode {
            saveButtonPressed(saveButton)
        }
        performSegueWithIdentifier(segueIdHomeInfoToHomeStory, sender: self)
    }
    
    @IBAction func neighborhoodButtonPressed(sender: UIButton) {
        if editMode {
            saveButtonPressed(saveButton)
        }
        performSegueWithIdentifier(segueIdHomeInfoToNeighborhood, sender: self)
    }
    
    @IBAction func editButtonPressed(sender: UIButton) {
        if appstate.mostRecentlyOpenedHome!.isMyHome() { // just sanity check
            backButton.hidden = true
            saveButton.hidden = false
            editButton.hidden = true
            editMode = true
            setSubviewEditModes()
        }
    }
    
    @IBAction func saveButtonPressed(sender: UIButton) {
        backButton.hidden = false
        saveButton.hidden = true
        editButton.hidden = false
        editMode = false
        
        setSubviewEditModes()
        
        let home = appstate.mostRecentlyOpenedHome
        dataManager.performUpdates({
            home?.localChanges = true
        })
        remoteService.updateMyHomeOnServer()  
    }
    
    @IBAction func backButtonPressed(button: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    /// Do not remove
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {}
        
    // MARK: Private methods
    
    /// Set editmode on or off for all the stackview subviews
    private func setSubviewEditModes() {
        for view in stackView.subviews {
            if let editableView = view as? EditableHomeInfoView {
                editableView.setEditMode(editMode, animated: false)
            } else if let galleryView = view as? GalleryStoryBlockCell {
                galleryView.setEditMode(editMode, animated: false)
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
        
        homeRoomsView.epcPressedCallback = {
            self.pickingMode = .EPC
            self.performSegueWithIdentifier(self.segueIdHomeInfoToHomeInfoImage, sender: self)
        }
        
        homeRoomsView.floorplanPressedCallback = {
            self.pickingMode = .FloorPlan
            self.performSegueWithIdentifier(self.segueIdHomeInfoToHomeInfoImage, sender: self)
        }
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
    
    /// Home info images
    private func addHomeImagesView() {
        let home = appstate.mostRecentlyOpenedHome!
        if home.isMyHome() || home.images.count > 0 {
            let homeImagesView = GalleryStoryBlockCell.instanceFromNib() as! GalleryStoryBlockCell
            stackView.addArrangedSubview(homeImagesView)
            
            homeImagesView.show(.HomeInfo, images: home.images, title: NSLocalizedString("gallerycell:home-images", comment: ""))
            
            homeImagesView.addImagesCallback = { [weak self] maxImages in
                self?.openImagePicker(maxSelections: 10, galleryView: homeImagesView)
            }
            
            homeImagesView.imageSelectedCallback = { [weak self] (imageIndex, imageView) in
                if imageView.image != nil {
                    if let strongSelf = self {
                        if !strongSelf.imageSelectionAnimationStarted {
                            strongSelf.imageSelectionAnimationStarted = true
                            strongSelf.performSegueWithIdentifier(strongSelf.segueIdHomeInfoToGalleryBrowser, sender: GallerySegueData(images: Array(home.images), imageIndex: imageIndex, imageView: imageView))
                        }
                    }
                }
            }
        }
    }
    
    /// Image selection
    private func openImagePicker(maxSelections maxSelections: Int? = nil, galleryView: GalleryStoryBlockCell? = nil) {
        let selectController = SelectStoryblockContentTypeViewController.create()
        
        selectController.maxSelections = maxSelections
        selectController.mediaType = .Image
        
        selectController.imageCallback = { [weak self] (images: [UIImage], originalImageAssetUrls: [String]?) in
            assert(NSThread.isMainThread(), "Must be called on the main thread!")
            
            log.debug("selected \(images.count) images")
            self?.imagesSelected(selectedImages: images, originalURLs: originalImageAssetUrls, galleryView: galleryView)
        }
        
        navigationController!.pushViewController(selectController, animated: false)
    }
    
    /// Upload images to cloudinary and assign image objects to home
    private func imagesSelected(selectedImages selectedImages: [UIImage], originalURLs: [String]?, galleryView: GalleryStoryBlockCell?) {
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
            if originalURLs != nil && originalURLs?.count > 0 {
                if let index = selectedImages.indexOf(selectedImage) where index < originalURLs!.count {
                    localUrl = originalURLs![index]
                }
            }
            
            let image = Image(url: fakeUrl, width: width, height: height, local: true, localUrl: localUrl, backgroundColor: selectedImage.averageColor().hexColor())
            image.uploadProgress = 0.0
            images.append(image)
            
            // Leave a mapping from the original UIImage to the Image object created
            imageMap[selectedImage] = image
        }
        
        dataManager.performUpdatesInRealm { realm in
            realm.add(images)
        }
        
        dataManager.performUpdates {
            appstate.mostRecentlyOpenedHome!.images.appendContentsOf(images)
        }
        
        // Redraw after images added to image gallery
        addSubviews()
        
        // Upload images to cloud
        for i in 0...selectedImages.count - 1 {
            let selectedImage = selectedImages[i]
            
            cloudStorage.uploadImage(selectedImage, progressCallback: { (progress) -> Void in
                if let image = imageMap[selectedImage] {
                    dataManager.performUpdates {
                        image.uploadProgress = progress
                    }
                }
                }, completionCallback: { (success: Bool, url: String?, width: Int?, height: Int?) -> Void in
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
                            
                            let home = appstate.mostRecentlyOpenedHome
                            dataManager.performUpdates({
                                home?.localChanges = true
                            })
                            
                            // Start fetching the (scaled) remote images
                            ImageCache.sharedInstance().getImage(url: image.scaledUrl, loadPolicy: .Network)
                        }
                    }
                })
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
    
    // Manages the bottom bar visibility based on the table view scroll
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
    
    
    func getCurrentFrameForGalleryImage(image: Image) -> CGRect? {
        let window = UIApplication.sharedApplication().keyWindow
        for subview in stackView.arrangedSubviews {
            
            // If image is in gallery get it's current frame
            if let galleryCell = subview as? GalleryStoryBlockCell {
                if galleryCell.hasImage(image) {
                    let imageFrameInGallery = galleryCell.frameForImage(image)
                    let galleryFrameInParentView = galleryCell.superview?.convertRect(galleryCell.frame, toView: window)
                    let frame = CGRectMake(imageFrameInGallery.origin.x + galleryFrameInParentView!.origin.x, galleryFrameInParentView!.origin.y + imageFrameInGallery.origin.y, imageFrameInGallery.width, imageFrameInGallery.height)
                    return frame
                }
            }
            
        }
        
        return nil
    }
    
    dynamic private func applicationWillResignActive(notification: NSNotification){
        self.saveButtonPressed(saveButton)
    }
    
    // MARK: Lifecycle
    
    private func addSubviews() {
        for subview in stackView.arrangedSubviews {
            subview.removeFromSuperview()
            stackView.removeArrangedSubview(subview)
        }
        
        addHeaderView()
        addRoomsView()
        addHomeImagesView()
        addDescriptionView()
        addFeaturesView()
        addMapSection()
        
        setSubviewEditModes()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        imageSelectionAnimationStarted = false
        
        if !editMode {
            saveButton.hidden = true
        }
        
        if !appstate.mostRecentlyOpenedHome!.isMyHome() {
            topBarHeightConstraint.constant = 0
            closeButton.hidden = false
        }
        
        toggleSettingsButtonVisibility()
        
        addSubviews()
        
        neighborhoodButton.enabled = false
        if let openedHome = appstate.mostRecentlyOpenedHome {
            if openedHome.userNeighborhood?.storyBlocks.count > 0 || openedHome.isMyHome() {
                neighborhoodButton.enabled = true
            }
        }
        
        // TODO Preload epc and floorplan when user opens home information????
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomBarOriginalHeight = bottomBarViewHeightConstraint.constant
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(HomeInfoViewController.applicationWillResignActive(_:)),
            name: "UIApplicationWillResignActiveNotification",
            object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdHomeInfoToHomeStory || segue.identifier == segueIdHomeInfoToNeighborhood {
            let homeStoryViewController = segue.destinationViewController as! HomeStoryViewController
            homeStoryViewController.hideBottomBarOriginally = false
        } else if segue.identifier == segueIdHomeInfoToHomeInfoImage {
            let homeInfoImageViewController = segue.destinationViewController as! HomeInfoImageViewController
            homeInfoImageViewController.editMode = editMode
            switch pickingMode {
            case .EPC:
                homeInfoImageViewController.pickingMode = .EPC
                if appstate.mostRecentlyOpenedHome!.epc != nil {
                    homeInfoImageViewController.image = appstate.mostRecentlyOpenedHome!.epc
                }
            case .FloorPlan:
                homeInfoImageViewController.pickingMode = .FloorPlan
                if appstate.mostRecentlyOpenedHome!.floorPlans.count > 0 {
                    homeInfoImageViewController.image = appstate.mostRecentlyOpenedHome!.floorPlans[0]
                }
            }
        } else if segue.identifier == segueIdHomeInfoToGalleryBrowser {
            let segueData = sender as! GallerySegueData
            let galleryController = segue.destinationViewController as! GalleryBrowserViewController
            let openImageSegue = segue as! OpenImageSegue
            
            if segueData.images.count > 0 {
                galleryController.images = segueData.images
            }
            
            galleryController.currentImageIndex = segueData.imageIndex
            openImageSegue.openedImageView = segueData.imageView
            galleryController.galleryType = .HomeInfo
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

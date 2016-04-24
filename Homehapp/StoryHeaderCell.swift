//
//  HomeStoryHeaderCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 19/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
 'Header' view placed on top of the large cell before any views formed from the story block.
 
 It displays the main image of the home and some additional controls for sharing, likes and comments.
 */
class StoryHeaderCell: UITableViewCell, EditableStoryCell, UITextViewDelegate {
    /// Main home image view. Accessible from outside for transitions.
    @IBOutlet weak var mainImageView: CachedImageView!

    /// Bottom part container view. Accessible from outside for transitions.
    @IBOutlet weak var bottomPartContainerView: UIView!

    @IBOutlet private weak var cameraButton: UIButton!
    @IBOutlet private weak var titleTextView: ExpandingTextView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var createdByLabel: UILabel!
    @IBOutlet private weak var addCoverPhotoLabel: UILabel!
    
    @IBOutlet private weak var bottomPartContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topPartContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleTextViewTopMarginConstraint: NSLayoutConstraint!
    
    /// Progress indicator for image upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!
    
    var addContentBottomButton: QvikButton?
    
    /// Action to be executed when share button is pressed
    var shareCallback: (Void -> Void)?

    var resizeCallback: (Void -> Void)? 

    var deleteCallback: (Void -> Void)?

    var updateCallback: (Void -> Void)?
    
    var addContentCallback: (AddContentButtonType -> Void)?

    /// Called when cell indicates that an image should be added (or current one replaced)
    var addImagesCallback: (Int? -> Void)?
    
    /// The scrollview this cell is currently a part of
    private var parentScrollView: UIScrollView? = nil
    
    var supportedTextEditModes: [StoryTextEditMode] {
        return [.HeaderOnly]
    }

    var storyObject: StoryObject? = nil {
        didSet {

            if let image = storyObject?.image {
                
                // TODO remove image url check when london-view removed from server in the future
                if !image.url.contains("london-view") {
                    
                    //Start loading proper image for header
                    mainImageView.imageUrl = image.scaledUrl
                    
                    //prior that display small scaled image that is used also in main screen list
                    mainImageView.placeholderImage = ImageCache.sharedInstance().getImage(url: image.smallScaledUrl, loadPolicy: .Memory)
                    
                    mainImageView.thumbnailData = image.thumbnailData
                    mainImageView.fadeInColor = UIColor.clearColor()
                    
                    if image.uploadProgress < 1.0 {
                        updateProgressBar()
                    }
                }
                
            } else {
                
                //Start loading proper image for header
                mainImageView.imageUrl = storyObject?.coverImage?.scaledUrl
                
                //prior that display small scaled image that is used also in main screen list
                if let smallScaledUrl = storyObject?.coverImage?.smallScaledUrl {
                    mainImageView.placeholderImage = ImageCache.sharedInstance().getImage(url: smallScaledUrl, loadPolicy: .Memory)
                }
                
                mainImageView.thumbnailData = storyObject?.coverImage?.thumbnailData
                mainImageView.fadeInColor = UIColor.clearColor()
            }
            
            if mainImageView.image == nil && mainImageView.placeholderImage == nil {
                mainImageView.thumbnailData = nil
                if storyObject is Neighborhood {
                    mainImageView.image = UIImage(named: "neighbourhood_default_background")
                } else {
                    mainImageView.image = UIImage(named: "home_default_background")
                }
            }
            
            if let title = storyObject?.title where title.length > 0 {
                titleTextView.text = title
                titleLabel.text = title.uppercaseString
            } else {
                if storyObject?.createdBy != nil {
                    if let firstName = storyObject!.createdBy!.firstName?.uppercaseString {
                        titleLabel.text =  "\(firstName)\(NSLocalizedString("homestorycell:someones-home", comment: ""))"
                    }
                }
            }
            
            locationLabel.text = appstate.mostRecentlyOpenedHome?.locationWithCity()
            
            if storyObject is Home {
                titleTextView.placeholderText = NSLocalizedString("edithomestory:header-placeholder", comment: "")
            } else {
                titleTextView.placeholderText = NSLocalizedString("editneighborhoodstory:header-placeholder", comment: "")
            }
            
            createdByLabel.text = ""
            if storyObject!.createdBy?.id != appstate.authUserId {
                if let user = storyObject!.createdBy, let fullName = user.fullName() {
                    createdByLabel.text = "\(NSLocalizedString("homestorycell:by", comment: "")) \(fullName)"
                }
            }
        }
    }

    // MARK: Private methods
    
    func tapped() {
        UIApplication.sharedApplication().sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, forEvent: nil)
    }
    
    /// Returns the UITableView this view is part of, if any
    private func getTableView() -> UITableView? {
        var v = self.superview
        
        while v != nil {
            if let tableView = v as? UITableView {
                return tableView
            }
            
            v = v?.superview
        }
        
        return nil
    }
    
    /// Removes the key-value observer for the current scroll view, if any
    private func removeScrollViewObserver() {
        if let scrollView = parentScrollView {
            scrollView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
            self.parentScrollView = nil
        }
    }
    
    /// Attempts to start listening to scroll events if attached to a scrollview
    private func handleViewHierarchyChange() {
        // End observing on the current scrollView as this may change
        removeScrollViewObserver()
        
        // Find the ancestor scrollView if one is available
        parentScrollView = getTableView()
        
        if let scrollView = parentScrollView {
            scrollView.addObserver(self, forKeyPath: "contentOffset", options: .New, context: nil)
            
            // Update initial transform
            scrollViewDidScroll(scrollView)
        }
    }
    
    private func updateProgressBar() {
        if let image = storyObject?.image {
            if image.uploadProgress < 1.0 {
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
    
    // MARK: Public methods

    /// Setup top / bottom container heights so that this cell fills the parent frame entirely
    func setupGeometry(parentSize parentSize: CGSize, bottomContainerAspectRatio: CGFloat, bottomBarHeight: CGFloat, hasLocation: Bool) {
        
        let margin: CGFloat = 20
        
        // Calculate the bottom container size from parent's size & requested aspect ratio
        bottomPartContainerHeightConstraint.constant = max(parentSize.width * bottomContainerAspectRatio + bottomBarHeight - margin, 135)
        
        // Top container height == what ever is left in parent frame
        topPartContainerHeightConstraint.constant = parentSize.height - bottomPartContainerHeightConstraint.constant
        
        // Title top margin constraint depends on if we have location for home of not
        if !hasLocation {
            titleTopMarginConstraint.constant = margin // Move title up if story has no location
            titleTextViewTopMarginConstraint.constant = margin - 8
        }

    }
    
    /// Adjusts the parallax / zoom-in effect by the scroll amount
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y

        // Parallax effect through translation; also used to keep the zoomed image in place.
        let yOffset = scrollOffset / 2
        let translate = CGAffineTransformMakeTranslation(0, yOffset)
        
        // Clip the cell contents when parallaxing ('scrolling down'), not while zooming in ('pulling down')
        clipsToBounds = (scrollOffset >= 0) ? true : false
        
        // Pull-down Zoom-in effect through scaling
        let scaleFactor = 1.0 + max(0, -scrollOffset / 300)

        let scale = CGAffineTransformMakeScale(scaleFactor, scaleFactor)
        
        mainImageView.transform = CGAffineTransformConcat(translate, scale)
    }
    
    func setEditMode(editMode: Bool, animated: Bool) {
        
        if editMode {
            addAddContentButton(.AddContentButtonTypeBottom, animated: animated)
        } else {
            removeAddContentButtons(animated)
        }
        
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            titleLabel.hidden = !(allVisible || !editMode)
            cameraButton.hidden = !(allVisible || editMode)
            addCoverPhotoLabel.hidden = !(allVisible || editMode)
            titleTextView.hidden = !(allVisible || editMode)
        }
        
        // Sets alpha attributes of the controls according to state
        func setControlAlphas() {
            titleLabel.alpha = editMode ? 0.0 : 1.0
            cameraButton.alpha = editMode ? 1.0 : 0.0
            addCoverPhotoLabel.alpha = editMode ? 1.0 : 0.0
            titleTextView.alpha = editMode ? 1.0 : 0.0
        }

        if !animated {
            setControlVisibility()
            setControlAlphas()
        } else {
            setControlVisibility(allVisible: true)
            
            UIView.animateWithDuration(0.3, animations: {
                setControlAlphas()
                }, completion: { finished in
                    setControlVisibility()                    
            })
        }
    }
    
    /// Add content addition button to cell
    private func addAddContentButton(addContentButtonType: AddContentButtonType, animated: Bool) {
        let addContentButton = QvikButton.button(frame: CGRect(x: 0, y: 0, width: addContentButtonSize, height: addContentButtonSize), type: .Custom) { [weak self] in
            self?.addContentCallback?(addContentButtonType)
        }
        
        addContentButton.setImage(UIImage(named: "icon_add_here"), forState: .Normal)
        addContentButton.contentMode = .Center
        addContentButton.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(addContentButton)
        addContentButton.layer.zPosition = 2
        
        addContentButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Constrain the delete button so that it will stay in the upper right corner of the cell
        var yConstraint: NSLayoutConstraint? = nil
        if addContentButtonType == .AddContentButtonTypeBottom {
            yConstraint = NSLayoutConstraint(item: addContentButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: addContentButtonSize / 2)
        } else {
            yConstraint = NSLayoutConstraint(item: addContentButton, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: -addContentButtonSize / 2)
        }
        let horizontalConstraint = NSLayoutConstraint(item: addContentButton, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: addContentButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: addContentButtonSize)
        let heightConstraint = NSLayoutConstraint(item: addContentButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: addContentButtonSize)
        
        NSLayoutConstraint.activateConstraints([yConstraint!, horizontalConstraint, widthConstraint, heightConstraint])
        
        // Layout once to put the add content button already in its proper place
        //layoutIfNeeded()
        self.addContentBottomButton = addContentButton
        
        if animated {
            addContentButton.alpha = 0.0
            UIView.animateWithDuration(toggleEditModeAnimationDuration) {
                addContentButton.alpha = 1.0
            }
        }
    }
    
    /// Remove content addition button from cell
    private func removeAddContentButtons(animated: Bool) {
        if animated {
            addContentBottomButton?.alpha = 1.0
            UIView.animateWithDuration(toggleEditModeAnimationDuration, animations: {
                self.addContentBottomButton?.alpha = 0.0
                }, completion: { finished in
                    self.addContentBottomButton?.removeFromSuperview()
                    self.addContentBottomButton = nil
            })
        } else {
            addContentBottomButton?.removeFromSuperview()
            addContentBottomButton = nil
        }
    }
    
    // MARK: From NSKeyValueObserving
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        scrollViewDidScroll(parentScrollView!)
    }
    
    // MARK: IBAction handlers
    
    @IBAction func shareButtonPressed(sender: UIButton) {
        shareCallback?()
    }
    
    @IBAction func selectPictureButtonPressed(sender: UIButton) {
        addImagesCallback?(1)
    }
    
    // MARK: From UITextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        titleTextView.text = titleTextView.text.trim()
        
        if storyObject?.title != titleTextView.text {
            
            // Save the home title
            dataManager.performUpdates {
                storyObject?.title = titleTextView.text
                
                // Mark local changes so that home is sent to server
                storyObject?.localChanges = true
            }
            
            updateCallback?()
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        if textView.text.length > 80 && text != "" {
            return false
        }
        return true
    }
    
    // MARK: From UIView
    
    override func didMoveToWindow() {
        handleViewHierarchyChange()
    }
    
    override func didMoveToSuperview() {
        handleViewHierarchyChange()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
   
        addContentBottomButton?.removeFromSuperview()
        addContentBottomButton = nil
    }
    
    // MARK: Lifecycle etc
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        mainImageView.fadeInColor = UIColor.whiteColor()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(StoryHeaderCell.tapped))
        addGestureRecognizer(tapRecognizer)
    }
}

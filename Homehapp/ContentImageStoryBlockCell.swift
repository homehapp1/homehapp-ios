//
//  ContentImageStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 20/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import KMPlaceholderTextView

/**
 Used to display 'ContentImage' layout style story block.
 */
class ContentImageStoryBlockCell: TextContentStoryBlockCell, UITextViewDelegate {
    let imageMargin: CGFloat = 3.0
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var editTitleTextView: KMPlaceholderTextView!
    @IBOutlet private weak var mainImageView: CachedImageView!
    
    @IBOutlet private var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var editTitleTextViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var editTitleTextViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var addImageButton: UIButton!
    
    // Progress indicator for image upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!
    
    /// Image selected -callback; can be used to open a full screen view
    var imageSelectedCallback: ((imageIndex: Int, imageView: UIImageView) -> Void)?

    override var storyBlock: StoryBlock? {
        didSet {
            titleLabel.text = storyBlock?.title
            editTitleTextView.text = ""
            editTitleTextView.scrollEnabled = true
            
            mainImageView.imageUrl = storyBlock?.image?.mediumScaledUrl
            if let thumbnailData = storyBlock?.image?.thumbnailData {
                mainImageView.thumbnailData = thumbnailData
            }
            
            if let fadeInColor = storyBlock?.image?.backgroundColor {
                mainImageView.fadeInColor = UIColor(hexString: fadeInColor)
            } else {
                mainImageView.fadeInColor = UIColor.lightGrayColor()
            }
            
            if let image = storyBlock?.image where image.uploadProgress < 1.0 {
                uploadProgressView.progress = image.uploadProgress
                updateProgressBar()
            }
        }
    }
    
    // MARK: Private methods
    
    private func updateProgressBar() {
        if let image = storyBlock?.image where image.uploadProgress < 1.0 {
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
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
        editTitleTextView.scrollEnabled = !editMode
        
        if !editMode && (titleLabel.text == nil || titleLabel.text?.length == 0) {
            titleLabelTopConstraint.active = true
            titleLabelBottomConstraint.active = true
            titleLabelTopConstraint.constant = imageMargin
            titleLabelBottomConstraint.constant = 0
            editTitleTextViewTopConstraint.active = false
            editTitleTextViewBottomConstraint.active = false
        } else {
            titleLabelTopConstraint.constant = 30
            titleLabelBottomConstraint.constant = 30
            titleLabelTopConstraint.active = !editMode
            titleLabelBottomConstraint.active = !editMode
            editTitleTextViewTopConstraint.active = editMode
            editTitleTextViewBottomConstraint.active = editMode
            editTitleTextView.text = editMode ? titleLabel.text : ""
        }
        
        if editMode {
            let size = editTitleTextView.sizeThatFits(CGSizeMake(editTitleTextView.width, 10000000))
            editTitleTextView.contentSize = size
            editTitleTextView.frame.size.height = size.height
            updateBorder(editTitleTextView.bounds)
        }
        
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            titleLabel.hidden = !(allVisible || !editMode)
            editTitleTextView.hidden = !(allVisible || editMode)
        }
        
        addImageButton.hidden = !editMode
        
        if !animated {
            setControlVisibility()
        } else {
            layoutIfNeeded()
            updateBorder(editTitleTextView.bounds)
            setControlVisibility()
        }
    }
    
    /// Returns true if this galleryBlock has given image
    func hasImage(image: Image) -> Bool {
        if let img = storyBlock?.image {
            if Image.getPublicId(img.url) == Image.getPublicId(image.url) {
                return true
            }
        }
        return false
    }
    
    /// Return current frame for given image
    func frameForImage(image: Image) -> CGRect {
        if hasImage(image) {
            return mainImageView.frame
        } else {
            return CGRectZero
        }
    }
    
    // MARK: From UITextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        titleLabel.text = editTitleTextView.text
        
        if storyBlock?.title != editTitleTextView.text {
            dataManager.performUpdates {
                storyBlock?.title = editTitleTextView.text
            }
            
            updateCallback?()
            resizeCallback?()
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
    
        let startHeight = textView.frame.size.height
        let calcHeight = textView.sizeThatFits(textView.frame.size).height
        
        if round(startHeight) != round(calcHeight) {
            
            UIView.setAnimationsEnabled(false) // Disable animations
            
            var tableView = self.superview
            while tableView as? UITableView == nil {
                tableView = tableView?.superview
            }
            
            let tv = tableView as! UITableView
            tv.beginUpdates()
            tv.endUpdates()
            
            let textViewFrameInTableView = tv.convertRect(textView.frame, fromView:textView.superview)
            tv.setContentOffset(CGPointMake(0, textViewFrameInTableView.y - tableView!.height + keyboardHeight + calcHeight), animated: false)
            
            updateBorder(editTitleTextView.bounds)
            
            UIView.setAnimationsEnabled(true)
        }
    }
    
    
    // MARK: IBAction handlers
    
    @IBAction func addImageButtonPressed(sender: UIButton) {
        addImagesCallback?(1)
    }
    
    /// Open image if tapped when not in edit mode
    func tapDetected() {
        if editTitleTextView.hidden {
            imageSelectedCallback!(imageIndex: 0, imageView: mainImageView)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        editTitleTextView.layer.addSublayer(borderLayer)

        let singleTap = UITapGestureRecognizer(target: self, action:#selector(ContentImageStoryBlockCell.tapDetected))
        mainImageView.userInteractionEnabled = true
        mainImageView.addGestureRecognizer(singleTap)
        
        updateBorder(titleLabel.bounds)
        
    }
}

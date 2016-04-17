//
//  ContentStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 18/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit

/**
 Displays a text-only block.
 */
class ContentStoryBlockCell: BaseStoryBlockCell, UITextViewDelegate {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var mainTextLabel: UILabel!
    
    @IBOutlet private weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainTextLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var editMainTextTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainTextLabelTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet private weak var editTitleLabelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var editTitleTextView: ExpandingTextView!
    @IBOutlet weak var editMainTextView: ExpandingTextView!
    
    var titleLabelOriginalTopMarginConstraint: CGFloat = 0
    
    override var resizeCallback: (Void -> Void)? {
        didSet {
            editTitleTextView.resizeCallback = resizeCallback
            editMainTextView.resizeCallback = resizeCallback
        }
    }

    override var supportedTextEditModes: [StoryTextEditMode] {
        return [.HeaderOnly, .BodyTextOnly, .HeaderAndBodyText]
    }

    override var storyBlock: StoryBlock? {
        didSet {
            if let title = storyBlock?.title {
                titleLabel.text = title.uppercaseString
                editTitleTextView.text = nil
            } else {
                titleLabel.text = ""
                editTitleTextView.text = nil
            }
            
            mainTextLabel.text = storyBlock?.mainText
            editMainTextView.text = nil
            
            // If content block is first cell, it should not have top margin
            if removeTopMargin {
                titleLabelTopConstraint.constant = 0
                editTitleLabelTopConstraint.constant = 0
            } else {
                titleLabelTopConstraint.constant = titleLabelOriginalTopMarginConstraint
                editTitleLabelTopConstraint.constant = 30
            }
        }
    }
    
    // MARK: Private methods
    
    /**
    Updates UI control visuals to match current layout.
    
    - returns: The text view that should become the next first responder, or nil if first responder should not change.
    */
    private func updateLayoutState() -> ExpandingTextView? {
        titleLabelHeightConstraint.active = false
        mainTextLabelHeightConstraint.active = false
        editMainTextTopMarginConstraint.constant = 0
        mainTextLabelTopMarginConstraint.constant = 10

        editTitleTextView.shouldResize = true
        editMainTextView.shouldResize = true
            
        return nil
    }
    
    // MARK: Public methods
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)

        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            titleLabel.hidden = !(allVisible || !editMode)
            mainTextLabel.hidden = !(allVisible || !editMode)

            editTitleTextView.hidden = !(allVisible || editMode)
            editMainTextView.hidden = !(allVisible || editMode)
            if !(allVisible || editMode) {
                editTitleTextView.text = nil
                editMainTextView.text = nil
            } else {
                editTitleTextView.text = titleLabel.text
                editMainTextView.text = mainTextLabel.text

            }
        }

        // Sets alpha attributes of the controls according to state
        func setControlAlphas() {
            titleLabel.alpha = editMode ? 0.0 : 1.0
            mainTextLabel.alpha = editMode ? 0.0 : 1.0
            
            editTitleTextView.alpha = editMode ? 1.0 : 0.0
            editMainTextView.alpha = editMode ? 1.0 : 0.0
        }
        
        editTitleTextView.heightConstraint.active = editMode
        editMainTextView.heightConstraint.active = editMode
        
        updateLayoutState()

        if !animated {
            setControlVisibility()
            setControlAlphas()
        } else {
            setControlVisibility(allVisible: true)
            
            UIView.animateWithDuration(toggleEditModeAnimationDuration, animations: {
                setControlAlphas()
                self.layoutIfNeeded()
                }, completion: { finished in
                    setControlVisibility()
            })
        }
    }
    
    // MARK: From UITextViewDelegate

    func textViewDidEndEditing(textView: UITextView) {
        titleLabel.text = editTitleTextView.text.uppercaseString
        mainTextLabel.text = editMainTextView.text
        
        if storyBlock?.title != editTitleTextView.text || storyBlock?.mainText != editMainTextView.text {
            // Save the home title
            dataManager.performUpdates {
                storyBlock?.title = editTitleTextView.text
                storyBlock?.mainText = editMainTextView.text
            }
            
            updateCallback?()
            //resizeCallback?()
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if textView == editTitleTextView {
                // "Next" pressed for title text view; move focus to main text view
                editMainTextView.becomeFirstResponder()
            } else {
                textView.resignFirstResponder()
            }
            
            return false
        }
        
        return true
    }
    
    // MARK: Lifecycle etc
    
    override func awakeFromNib() {
        super.awakeFromNib()

        editTitleTextView.placeholderText = NSLocalizedString("edithomestory:content:title-placeholder", comment: "")
        editMainTextView.placeholderText = NSLocalizedString("edithomestory:content:maintext-placeholder", comment: "")
        
        titleLabelOriginalTopMarginConstraint = titleLabelTopConstraint.constant
        
        layer.shouldRasterize = true
        layer.rasterizationScale = 2.0
    }
}
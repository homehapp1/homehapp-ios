//
//  ContentDescriptionStoryBlockCell.swift
//  Homehapp
//
//  Created by Lari Tuominen on 31.3.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit
import KMPlaceholderTextView

class ContentDescriptionStoryBlockCell: TextContentStoryBlockCell, UITextViewDelegate {

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var descriptionTextView: KMPlaceholderTextView!
    
    @IBOutlet private var descriptionLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private var descriptionLabelBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private var descriptionTextViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var descriptionTextViewBottomConstraint: NSLayoutConstraint!
    
    var descriptionLabelOriginalTopMarginConstraint: CGFloat = 0
    var descriptionTextviewOriginalTopMarginConstraint: CGFloat = 0
 
    override var storyBlock: StoryBlock? {
        didSet {
            if let mainText = storyBlock?.mainText {
                descriptionLabel.text = mainText
            } else {
                descriptionLabel.text = ""
                descriptionTextView.text = ""
            }
            descriptionTextView.scrollEnabled = true
            
            // If content block is first cell, it should not have top margin
            
            if removeTopMargin {
                descriptionLabelTopConstraint.constant = 0
                descriptionTextViewTopConstraint.constant = 0
            } else {
                descriptionLabelTopConstraint.constant = descriptionLabelOriginalTopMarginConstraint
                descriptionTextViewTopConstraint.constant = descriptionTextviewOriginalTopMarginConstraint
            }
        }
    }
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
        descriptionTextView.scrollEnabled = !editMode
        if editMode {
            descriptionTextView.text = descriptionLabel.text
            descriptionTextViewTopConstraint.active = true
            descriptionTextViewBottomConstraint.active = true
            descriptionLabelTopConstraint.active = false
            descriptionLabelBottomConstraint.active = false
            descriptionTextView.contentSize = descriptionTextView.bounds.size
            updateBorder(descriptionTextView.bounds)
        } else {
            descriptionTextView.text = ""
            descriptionTextViewTopConstraint.active = false
            descriptionTextViewBottomConstraint.active = false
            descriptionLabelTopConstraint.active = true
            descriptionLabelBottomConstraint.active = true
        }
        
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            descriptionLabel.hidden = !(allVisible || !editMode)
            descriptionTextView.hidden = !(allVisible || editMode)
        }
        
        if !animated {
            setControlVisibility()
        } else {
            self.layoutIfNeeded()
            self.updateBorder(self.descriptionTextView.bounds)
            setControlVisibility()
        }
    }
    
    // MARK: From UITextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        descriptionLabel.text = descriptionTextView.text
        
        if storyBlock?.mainText != descriptionTextView.text {
            // Save the storyBlock main text
            dataManager.performUpdates {
                storyBlock?.mainText = descriptionTextView.text
            }
            
            updateCallback?()
            resizeCallback?()
        }
    }
    
    // MARK: UITextViewDelegate
    func textViewDidChange(textView: UITextView) {
        
        let startHeight = textView.frame.size.height
        let calcHeight = textView.sizeThatFits(textView.frame.size).height
        
        if startHeight != calcHeight {
            
            UIView.setAnimationsEnabled(false) // Disable animations
            
            var tableView = self.superview
            while tableView as? UITableView == nil {
                tableView = tableView?.superview
            }
            
            let tv = tableView as! UITableView
            tv.beginUpdates()
            tv.endUpdates()
            
            // change contentOffset only if textview is about to go under to keyboard
            //let textViewFrameInWindow = textView.convertRect(textView.bounds, toView: nil)
            // TODO
            
            //if textViewFrameInWindow.y + calcHeight > tv.height - keyboardHeight {
            let textViewFrameInTableView = tv.convertRect(textView.frame, fromView:textView.superview)
            tv.setContentOffset(CGPointMake(0, textViewFrameInTableView.y - tableView!.height + keyboardHeight + calcHeight), animated: false)
            //}
            
            updateBorder(descriptionTextView.bounds)
            
            UIView.setAnimationsEnabled(true)
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    // MARK: Lifecycle etc
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        descriptionTextView.layer.addSublayer(borderLayer)
        descriptionTextView.layoutManager.allowsNonContiguousLayout = true
        descriptionTextView.dataDetectorTypes = .None
        
        descriptionLabelOriginalTopMarginConstraint = descriptionLabelTopConstraint.constant
        descriptionTextviewOriginalTopMarginConstraint = descriptionTextViewTopConstraint.constant
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.frame.size.width
        super.layoutSubviews()
        updateBorder(descriptionTextView.bounds)
    }
    
}

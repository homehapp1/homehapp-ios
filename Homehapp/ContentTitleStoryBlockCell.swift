//
//  ContentTitleStoryBlockCell.swift
//  Homehapp
//
//  Created by Lari Tuominen on 25.3.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit
import KMPlaceholderTextView

class ContentTitleStoryBlockCell: TextContentStoryBlockCell, UITextViewDelegate {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleTextView: KMPlaceholderTextView!
    
    @IBOutlet private var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private var titleLabelBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private var titleTextViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var titleTextViewBottomConstraint: NSLayoutConstraint!
    
    var titleLabelOriginalTopMarginConstraint: CGFloat = 0
    var titleTextviewOriginalTopMarginConstraint: CGFloat = 0
    
    override var storyBlock: StoryBlock? {
        didSet {
            if let title = storyBlock?.title {
                titleLabel.text = title
            } else {
                titleLabel.text = ""
                titleTextView.text = ""
            }
            titleTextView.scrollEnabled = true
            
            if removeTopMargin && !editMode {
                titleLabelTopConstraint.constant = 0
                titleTextViewTopConstraint.constant = 0
            } else {
                titleLabelTopConstraint.constant = titleLabelOriginalTopMarginConstraint
                titleTextViewTopConstraint.constant = titleTextviewOriginalTopMarginConstraint
            }
        }
    }
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
    
        titleTextView.scrollEnabled = !editMode
        if editMode {
            titleTextView.text = titleLabel.text
            titleTextViewTopConstraint.active = true
            titleTextViewBottomConstraint.active = true
            titleLabelTopConstraint.active = false
            titleLabelBottomConstraint.active = false
            titleTextView.contentSize = titleTextView.bounds.size
            updateBorder(titleTextView.bounds)
        } else {
            titleTextView.text = ""
            titleTextViewTopConstraint.active = false
            titleTextViewBottomConstraint.active = false
            titleLabelTopConstraint.active = true
            titleLabelBottomConstraint.active = true
        }
        
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            titleLabel.hidden = !(allVisible || !editMode)
            titleTextView.hidden = !(allVisible || editMode)
        }
        
        if !animated {
            setControlVisibility()
        } else {
            self.layoutIfNeeded()
            self.updateBorder(self.titleTextView.bounds)
            setControlVisibility()
        }
    }
    
    // MARK: From UITextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        titleLabel.text = titleTextView.text
        
        if storyBlock?.title != titleTextView.text {
            // Save the story block title
            dataManager.performUpdates {
                storyBlock?.title = titleTextView.text
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
            
            updateBorder(titleTextView.bounds)
            
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
        
        titleTextView.layer.addSublayer(borderLayer)
        
        titleLabelOriginalTopMarginConstraint = titleLabelTopConstraint.constant
        titleTextviewOriginalTopMarginConstraint = titleTextViewTopConstraint.constant
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.preferredMaxLayoutWidth = titleLabel.frame.size.width
        super.layoutSubviews()
        updateBorder(titleTextView.bounds)
    }
    
}

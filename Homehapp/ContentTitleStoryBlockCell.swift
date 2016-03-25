//
//  ContentTitleStoryBlockCell.swift
//  Homehapp
//
//  Created by Lari Tuominen on 25.3.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class ContentTitleStoryBlockCell: BaseStoryBlockCell, UITextViewDelegate {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleTextView: UITextView!
    
    private var borderLayer: CAShapeLayer!
    
    override var resizeCallback: (Void -> Void)? {
        didSet {
            //titleTextView.resizeCallback = resizeCallback
        }
    }
    
    override var storyBlock: StoryBlock? {
        didSet {
            if let title = storyBlock?.title {
                titleLabel.text = title
                titleTextView.text = title
            } else {
                titleLabel.text = ""
                titleTextView.text = ""
            }
        }
    }
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
    
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            titleLabel.hidden = !(allVisible || !editMode)
            titleTextView.hidden = !(allVisible || editMode)
        }
        
        // Sets alpha attributes of the controls according to state
        func setControlAlphas() {
            titleLabel.alpha = editMode ? 0.0 : 1.0
            titleTextView.alpha = editMode ? 1.0 : 0.0
        }
        
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
        titleLabel.text = titleTextView.text
        
        if storyBlock?.title != titleTextView.text {
            // Save the home title
            dataManager.performUpdates {
                storyBlock?.title = titleTextView.text
            }
            
            updateCallback?()
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
            
            updateBorder()
            
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
        
        //titleTextView.placeholderText = NSLocalizedString("edithomestory:content:title-placeholder", comment: "")
        layer.shouldRasterize = true
        layer.rasterizationScale = 2.0
        
        borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor(red:0.0, green:0.0, blue:0.0, alpha:0.5).CGColor
        borderLayer.fillColor = nil
        borderLayer.lineDashPattern = [3, 3]
        borderLayer.lineWidth = 1.0
        titleTextView.layer.addSublayer(borderLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateBorder()
    }

    func updateBorder() {
        borderLayer.path = UIBezierPath(rect: titleTextView.bounds).CGPath
        borderLayer.frame = titleTextView.bounds
        borderLayer.frame.origin.y = 0
    }
    
}

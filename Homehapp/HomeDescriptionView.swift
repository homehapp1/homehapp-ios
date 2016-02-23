//
//  HomeDescriptionView.swift
//  Homehapp
//
//  Created by Lari Tuominen on 11.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class HomeDescriptionView: UIView, EditableHomeInfoView, UITextViewDelegate {

    @IBOutlet private weak var descriptionTextView: ExpandingTextView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    var home: Home? = nil {
        didSet {
            descriptionTextView.text = home?.homeDescription
            descriptionLabel.text = home?.homeDescription
            
            descriptionLabel.hidden = false
            descriptionTextView.hidden = true
        }
    }
    
    func setEditMode(editMode: Bool, animated: Bool) {
        descriptionTextView.hidden = !editMode
        descriptionLabel.hidden = editMode
        
        if descriptionTextView.isFirstResponder() {
            textViewDidEndEditing(descriptionTextView)
            descriptionTextView.resignFirstResponder()
        }
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        dataManager.performUpdates({
            home?.homeDescription = textView.text
            descriptionLabel.text = textView.text
        })
        remoteService.updateMyHomeOnServer()
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    // MARK: Private functions

    // MARK: Lifecycle

    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HomeDescriptionView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UIView
    }

}

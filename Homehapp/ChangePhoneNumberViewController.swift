//
//  ChangePhoneNumberViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 17.1.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class ChangePhoneNumberViewController: BaseViewController {

    @IBOutlet private weak var phoneNumberTextField: UITextField!
    
    @IBAction func doneButtonPressed(sender: UIButton) {
        if let currentUser = dataManager.findCurrentUser() {
            dataManager.performUpdates({
                currentUser.phoneNumber = phoneNumberTextField.text
            })
        }
        remoteService.updateCurrentUserOnServer()
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func cancelButtonPressed(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
        if let currentUser = dataManager.findCurrentUser() {
            phoneNumberTextField.text = currentUser.phoneNumber
        }
    }
    
    override func viewDidLoad() {
       super.viewDidLoad()
    }
    
}

//
//  HomeSettingsViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 17.1.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class HomeSettingsViewController: BaseViewController {
    private let segueIdHomeSettingsToNeighborhood = "HomeSettingsToNeighborhood"
    private let segueIdHomeSettingsToHomeStory = "homeSettingsToHomeStory"
    private let segueIdHomeSettingsToHomeInfo = "homeSettingsToHomeInfo"
    
    /// Neighborhood button in bottom bar
    @IBOutlet private weak var neighborhoodButton: UIButton!
    
    @IBOutlet private weak var visibilitySwitch: UISwitch!
    
    @IBAction func homeStoryButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdHomeSettingsToHomeStory, sender: self)
    }
    
    @IBAction func homeInfoButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(segueIdHomeSettingsToHomeInfo, sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdHomeSettingsToHomeStory || segue.identifier == segueIdHomeSettingsToNeighborhood {
            let homeStoryViewController = segue.destinationViewController as! HomeStoryViewController
            homeStoryViewController.allowEditMode = true
            homeStoryViewController.hideBottomBarOriginally = false
        }
    }

    @IBAction func neighborhoodButtonPressed(button: UIButton) {
        performSegueWithIdentifier(segueIdHomeSettingsToNeighborhood, sender: self)
    }
    
    @IBAction func visibilitySwitchValueChanged (sender: UISwitch) {
        let myHome = appstate.mostRecentlyOpenedHome
        dataManager.performUpdates({
            myHome!.isPublic = sender.on
        })
        remoteService.updateMyHomeOnServer()
    }
    
    @IBAction func backButtonPressed(button: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }

    // MARK: - Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        visibilitySwitch.on = appstate.mostRecentlyOpenedHome!.isPublic
        visibilitySwitch.onTintColor = UIColor.homehappColorActive()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        neighborhoodButton.enabled = false
        if let openedHome = appstate.mostRecentlyOpenedHome {
            if openedHome.userNeighborhood?.storyBlocks.count > 0 || openedHome.isMyHome() {
                neighborhoodButton.enabled = true
            }
        }
    }
}

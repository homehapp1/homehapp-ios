//
//  HomeRoomsView.swift
//  Homehapp
//
//  Created by Lari Tuominen on 5.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class HomeRoomsView: UIView, EditableHomeInfoView {

    @IBOutlet private weak var bedroomsLabel: UILabel!
    @IBOutlet private weak var bathroomsLabel: UILabel!
    @IBOutlet private weak var otherRoomsLabel: UILabel!
    
    @IBOutlet private weak var removeBedroomsButton: UIButton!
    @IBOutlet private weak var addBedroomsButton: UIButton!
    @IBOutlet private weak var removeBathroomsButton: UIButton!
    @IBOutlet private weak var addBathroomsButton: UIButton!
    @IBOutlet private weak var removeOtherRoomsButton: UIButton!
    @IBOutlet private weak var addOtherRoomsButton: UIButton!
    
    var home: Home? = nil {
        didSet {
            displayRoomTexts()
            setEditMode(false, animated: false)
        }
    }
    
    func setEditMode(editMode: Bool, animated: Bool) {
        removeBedroomsButton.hidden = !editMode
        addBedroomsButton.hidden = !editMode
        removeBathroomsButton.hidden = !editMode
        addBathroomsButton.hidden = !editMode
        removeOtherRoomsButton.hidden = !editMode
        addOtherRoomsButton.hidden = !editMode
    }
    
    // MARK Private methods
    
    private func displayRoomTexts() {
        
        guard let home = home else {
            log.debug("Home cannot be nil")
            return
        }
        
        bedroomsLabel.text = home.bedrooms != 0 ? "\(home.bedrooms)" : "-"
        bathroomsLabel.text = home.bathrooms != 0 ? "\(home.bathrooms)" : "-"
        otherRoomsLabel.text = home.otherRooms != 0 ? "\(home.otherRooms)" : "-"
    }
    
    // MARK: IBActions
    
    @IBAction func removeBedroomButtonPressed(sender: UIButton) {
        dataManager.performUpdates({
            if home!.bedrooms > 0 {
                home!.bedrooms = home!.bedrooms - 1
            }
        })
        displayRoomTexts()
    }
    
    @IBAction func addBedroomButtonPressed(sender: UIButton) {
        dataManager.performUpdates({
            home!.bedrooms = home!.bedrooms + 1
        })
        displayRoomTexts()
    }
    
    @IBAction func removeBathroomButtonPressed(sender: UIButton) {
        dataManager.performUpdates({
            if home!.bathrooms > 0 {
                home!.bathrooms = home!.bathrooms - 1
            }
        })
        displayRoomTexts()
    }

    @IBAction func addBathroomButtonPressed(sender: UIButton) {
        dataManager.performUpdates({
            home!.bathrooms = home!.bathrooms + 1
        })
        displayRoomTexts()
    }
    
    @IBAction func removeOtherRoomButtonPressed(sender: UIButton) {
        dataManager.performUpdates({
            if home!.otherRooms > 0 {
                home!.otherRooms = home!.otherRooms - 1
            }
        })
        displayRoomTexts()
    }

    @IBAction func addOtherRoomButtonPressed(sender: UIButton) {
        dataManager.performUpdates({
            home!.otherRooms = home!.otherRooms + 1
        })
        displayRoomTexts()
    }
    
    // MARK: Lifecycle
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HomeRoomsView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UIView
    }
   
}

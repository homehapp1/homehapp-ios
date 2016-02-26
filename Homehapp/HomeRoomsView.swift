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
    
    @IBOutlet private weak var floorPlanbutton: UIButton!
    @IBOutlet private weak var epcButton: UIButton!
    
    @IBOutlet private weak var floorPlanButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var floorPlanButtonBottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet private weak var epcButtonHeightConstraint: NSLayoutConstraint!
    
    private var originalFloorPlanButtonHeight: CGFloat = 0
    private var originalFloorPlanButtonBottomMargin: CGFloat = 0
    private var originalEpcButtonHeight: CGFloat = 0
    
    // Callback called when EPC button is pressed
    var epcPressedCallback: (Void -> Void)?
    
    // Callback called when FloorPlan button is pressed
    var floorplanPressedCallback: (Void -> Void)?
    
    var home: Home? = nil {
        didSet {
            guard let home = home else {
                log.error("Missing home!")
                return
            }
            
            displayRoomTexts()
            setEditMode(false, animated: false)
            
            // Determine if we show epc or floorplan button based on if user is owner
            if home.isMyHome() {
                floorPlanButtonHeightConstraint.constant = originalFloorPlanButtonHeight
                floorPlanButtonBottomMarginConstraint.constant = originalFloorPlanButtonBottomMargin
                epcButtonHeightConstraint.constant = originalEpcButtonHeight
            } else {
                floorPlanButtonHeightConstraint.constant = home.floorPlans.count > 0 ? originalFloorPlanButtonHeight : 0
                floorPlanButtonBottomMarginConstraint.constant = home.floorPlans.count > 0 ? originalFloorPlanButtonBottomMargin : 0
                epcButtonHeightConstraint.constant = home.epcs.count > 0 ? originalEpcButtonHeight : 0
            }
        }
    }
    
    func setEditMode(editMode: Bool, animated: Bool) {
        removeBedroomsButton.hidden = !editMode
        addBedroomsButton.hidden = !editMode
        removeBathroomsButton.hidden = !editMode
        addBathroomsButton.hidden = !editMode
        removeOtherRoomsButton.hidden = !editMode
        addOtherRoomsButton.hidden = !editMode
        
        floorPlanbutton.enabled = editMode
        epcButton.enabled = editMode
        
        floorPlanbutton.backgroundColor = editMode ? UIColor.homehappColorActive() : UIColor.homehappDarkColor()
        epcButton.backgroundColor = editMode ? UIColor.homehappColorActive() : UIColor.homehappDarkColor()
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
    
    @IBAction func epcButtonPressed(button: UIButton) {
        if home?.epcs.count > 0 || home!.isMyHome() {
            epcPressedCallback?()
        }
    }
    
    @IBAction func floorPlanButtonPressed(button: UIButton) {
        if home?.floorPlans.count > 0 || home!.isMyHome() {
            floorplanPressedCallback?()
        }
    }
    
    // MARK: Lifecycle
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HomeRoomsView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UIView
    }
    
    override func awakeFromNib() {
        originalFloorPlanButtonHeight = floorPlanButtonHeightConstraint.constant
        originalFloorPlanButtonBottomMargin = floorPlanButtonBottomMarginConstraint.constant
        originalEpcButtonHeight = epcButtonHeightConstraint.constant
    }
   
}

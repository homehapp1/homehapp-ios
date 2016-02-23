//
//  ProfileViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 22.12.2015.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import QvikNetwork
import CoreLocation

let profileToChangePhoneNumberSegueIdentifier = "profileToChangePhoneNumber"
let profileToHomesSegueIdentifier = "profileToHomesSegueIdentifier"

class ProfileViewController: BaseViewController, UIImagePickerControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet private weak var profileImage: CachedImageView!
    @IBOutlet private weak var defaultProfileImage: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var placeButton: UIButton!
    @IBOutlet private weak var loggedInLabel: UILabel!
    @IBOutlet private weak var telephoneButton: UIButton!
    @IBOutlet private weak var pushNotifications: UISwitch!
    @IBOutlet private weak var privateMessages: UISwitch!
    
    private let imagePicker = UIImagePickerController()
    private let profileImageMaxSize: CGSize = CGSizeMake(360, 360)
    private var locationManager: CLLocationManager?
    
    @IBAction func closeButtonPressed(sender: UIButton!) {
        self.performSegueWithIdentifier("profileToHomesSegueIdentifier", sender: self)
    }
    
    @IBAction func logoutButtonPressed(sender: UIButton) {
        let alert = UIAlertController(title: "Confirm log out",
            message: "Really log out? We already miss you!",
            preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Log out", style: UIAlertActionStyle.Destructive, handler: { action in
            NSNotificationCenter.defaultCenter().postNotificationName(userLogoutNotification, object: self)
            self.navigationController?.popToRootViewControllerAnimated(true)
            AuthenticationService.sharedInstance().logoutUser()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func profileImageButtonPressed(sender: UIButton) {
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func placeButtonPressed(sender: UIButton) {
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.requestAlwaysAuthorization()
        locationManager!.startUpdatingLocation()
    }
    
    @IBAction func telephoneButtonPressed(sender: UIButton) {
        performSegueWithIdentifier(profileToChangePhoneNumberSegueIdentifier, sender: self)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let scaledImage = pickedImage.scaleDown(maxSize: profileImageMaxSize)
            profileImage.image = scaledImage
            
            dismissViewControllerAnimated(true, completion: nil)
            
            cloudStorage.uploadImage(scaledImage, progressCallback: { (progress) in
                }, completionCallback: { (success: Bool, url: String?, width: Int?, height: Int?) -> Void in

                    let imageUrl = url != nil ? url! : ""
                    let localImageUrl = info[UIImagePickerControllerReferenceURL] as? NSURL
                    let userImage = Image(url: imageUrl, width: Int(scaledImage.width), height: Int(scaledImage.height), localUrl: localImageUrl?.absoluteString)

                    if success {
                        userImage.url = url!
                        userImage.local = false
                    } else {
                        userImage.local = true
                    }
                    
                    ImageCache.sharedInstance().putImage(image: scaledImage, url: imageUrl, storeOnDisk: true)
                    
                    dataManager.performUpdates({
                        dataManager.findCurrentUser()?.profileImage = userImage
                    })
                    
                    if success {
                        remoteService.updateCurrentUserOnServer()
                    }
            })
        }
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            CLGeocoder().reverseGeocodeLocation(locations[0]) {[weak self] (placemarks, error) in
                if self?.locationManager != nil {
                    if let placeMarks = placemarks {
                        let currentUser = dataManager.findCurrentUser()
                        dataManager.performUpdates({
                            if let country = placeMarks[0].country {
                                currentUser?.country = country
                            }
                            if let city = placeMarks[0].locality {
                                currentUser?.city = city
                            }
                            if let neighbourhood = placeMarks[0].subLocality {
                                currentUser?.neighbourhood = neighbourhood
                            }
                        
                            remoteService.updateCurrentUserOnServer()
                            self?.placeButton.setTitle(currentUser?.locationString(), forState: .Normal)
                        
                            self?.locationManager!.stopUpdatingLocation()
                        
                            //avoid multiple calls to this method. stopUpdating not enough
                            self?.locationManager = nil
                        })
                    }
                }
            }
        }
    }
    
    // MARK: Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let user = DataManager.sharedInstance().findCurrentUser() else {
            log.error("User not found!");
            return
        }
        
        if user.profileImage != nil {
            if let profileImageURL = user.profileImage?.url where profileImageURL.length > 0 {
                profileImage.imageUrl = profileImageURL
            } else {
                if let localImageURL = user.profileImage?.localUrl {
                    requestImageDataForAssetUrl(NSURL(string: localImageURL)!, callback: { [weak self] (imageData) -> Void in
                        self?.profileImage.image = UIImage(data: imageData)
                    })
                }
            }
            profileImage.imageFadeInDuration = 0.4
            profileImage.fadeInColor = UIColor.whiteColor()
            defaultProfileImage.hidden = true
        }
        
        if let _ = user.facebookUserId {
            loggedInLabel.text = NSLocalizedString("profileviewcontroller:logged-id", comment: "") + " FACEBOOK"
        } else {
            loggedInLabel.text = NSLocalizedString("profileviewcontroller:logged-id", comment: "") + " GOOGLE"
        }
        
        if let firstName = user.firstName {
            if let lastName = user.lastName {
                nameLabel.text = "\(firstName)  \(lastName)".uppercaseString
            } else {
                nameLabel.text = "\(firstName)".uppercaseString
            }
        }
        
        if user.locationString() != nil {
            placeButton.setTitle(user.locationString(), forState: .Normal)
        } else {
            placeButton.setTitle(NSLocalizedString("profileviewcontroller:add-neighbourhood", comment: ""), forState: .Normal)
        }
        
        if user.phoneNumber != nil {
            telephoneButton.setTitle(user.phoneNumber, forState: .Normal)
        }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        locationManager?.stopUpdatingLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pushNotifications.onTintColor = UIColor.homehappColorActive()
        privateMessages.onTintColor = UIColor.homehappColorActive()
        
        imagePicker.delegate = self
        
    }
}

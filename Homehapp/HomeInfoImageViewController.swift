//
//  HomeInfoImageViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 25.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

/// Defines if we're watching EPC of Floorplans
enum ImagePickingMode: String {
    case EPC = "EPC"
    case FloorPlan = "FloorPlan"
}

class HomeInfoImageViewController: BaseViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate {
    
    /// Displays main image in this view
    @IBOutlet weak var imageView: CachedImageView!
    
    /// Change image button
    @IBOutlet weak var editImageButton: UIButton!
    
    /// Delete button
    @IBOutlet weak var deleteButton: UIButton!
    
    /// Progress indicator for image upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!
    
    /// Loading indicator for image loading
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    
    /// Image selected and displayed
    var image: Image? = nil
    
    /// Picking mode, for what purposes we're picking image
    var pickingMode: ImagePickingMode = .EPC
    
    /// Defines if this view is in edit mode or not
    var editMode: Bool = false
    
    /// Picker controller to change the image in this view
    var imagePicker = UIImagePickerController()
    
    private let segueIdhomeInfoImageToHomeInfo = "HomeInfoImageToHomeInfo"
    
    // MARK: IBActions
    
    @IBAction func editImageButtonPressed(button: UIButton) {
        if appstate.mostRecentlyOpenedHome!.isMyHome() {
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
            imagePicker.delegate = self
            presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func closeButtonPressed(button: UIButton) {
        self.performSegueWithIdentifier(self.segueIdhomeInfoImageToHomeInfo, sender: self)
    }
    
    @IBAction func deleteButtonPressed(button: UIButton) {
        if appstate.mostRecentlyOpenedHome!.isMyHome() {
            deleteButton.enabled = false
        
            // Remove image fom local database
            switch pickingMode {
            case .EPC:
                dataManager.performUpdates({
                    appstate.mostRecentlyOpenedHome!.epc = nil
                })
            case .FloorPlan:
                dataManager.performUpdates({
                    appstate.mostRecentlyOpenedHome!.floorPlans.removeAll() // TODO support for multiple floorplans
                })
            }
        
            // Remove image from Cloudinary
            if let url = image?.url where url.contains("http") {
                //cloudStorage.removeAsset(url)
            }
        
            // Animate image removal
            UIView.animateWithDuration(0.4, animations: {
                self.imageView.alpha = 0.0
                }) { finished in
                    self.image = nil
                    self.imageView.image = nil
                    self.imageView.alpha = 1.0
                    self.deleteButton.enabled = true
            }
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // MARK: UIImagePickerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        uploadProgressView.hidden = false
        uploadProgressView.progress = 0
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            editImageButton.hidden = true
            imageView.image = image
            cloudStorage.uploadImage(image, progressCallback: { [weak self] (progress) in
                    self?.uploadProgressView.progress = progress
                }, completionCallback: { [weak self] (success: Bool, url: String?, width: Int?, height: Int?) -> Void in
                    let imageUrl = url != nil ? url! : ""
                    let localImageUrl = info[UIImagePickerControllerReferenceURL] as? NSURL
                    let pickedImage = Image(url: imageUrl, width: Int(image.width), height: Int(image.height), localUrl: localImageUrl?.absoluteString, backgroundColor: image.averageColor().hexColor())
    
                    self?.uploadProgressView.hidden = true
                    self?.editImageButton.hidden = false
                    
                    if success {
                        pickedImage.url = url!
                        pickedImage.local = false
                        let scaledCloudinaryUrl = pickedImage.scaledUrl
                        ImageCache.sharedInstance().putImage(image: image, url: scaledCloudinaryUrl, storeOnDisk: true)
                    } else {
                        pickedImage.local = true
                    }
                
                    dataManager.performUpdates({
                        if let pickingMode = self?.pickingMode {
                            switch pickingMode {
                            case .EPC:
                                appstate.mostRecentlyOpenedHome?.epc = pickedImage
                            case .FloorPlan:
                                appstate.mostRecentlyOpenedHome?.floorPlans.removeAll()
                                appstate.mostRecentlyOpenedHome?.floorPlans.append(pickedImage)
                            }
                        }   
                    })
                
                    if success {
                        remoteService.updateMyHomeOnServer()
                    }
                })
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Lifecycle
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .LandscapeLeft, .LandscapeRight]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !appstate.mostRecentlyOpenedHome!.isMyHome() && imageView.image == nil {
            loadingIndicator.startAnimating()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = image {
            imageView.imageUrl = image.scaledUrl
            imageView.thumbnailData = image.thumbnailData
            imageView.fadeInColor = UIColor.blackColor()
            imageView.imageFadeInDuration = 0
            imageView.imageChangedCallback = {
                self.loadingIndicator.stopAnimating()
            }
        }
        
        editImageButton.hidden = (!appstate.mostRecentlyOpenedHome!.isMyHome() || editMode == false)
        deleteButton.hidden = (!appstate.mostRecentlyOpenedHome!.isMyHome() || editMode == false)
    }
}

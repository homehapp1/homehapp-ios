//
//  HomeInfoImageViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 25.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit
import QvikNetwork

/// Describes the available text editing modes for home story cells
enum ImagePickingMode: String {
    case EPC = "EPC"
    case FloorPlan = "FloorPlan"
}

class HomeInfoImageViewController: BaseViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: CachedImageView!
    
    /// Change image button
    @IBOutlet weak var editImageButton: UIButton!
    
    /// Progress indicator for image upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!
    
    /// Image selected and displayed
    var image: Image? = nil
    
    /// Picking mode, for what purposes we're picking image
    var pickingMode: ImagePickingMode = .EPC
    
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
        self.performSegueWithIdentifier(segueIdhomeInfoImageToHomeInfo, sender: self)
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
                                appstate.mostRecentlyOpenedHome?.epcs.removeAll()
                                appstate.mostRecentlyOpenedHome?.epcs.append(pickedImage)
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = image {
            imageView.imageUrl = image.scaledUrl
            imageView.thumbnailData = image.thumbnailData
            imageView.fadeInColor = UIColor.blackColor()
            /* Not correct aspect ratio
            if let fadeInColor = image.backgroundColor {
                imageView.fadeInColor = UIColor(hexString: fadeInColor)
            }
            */
            
            imageView.imageFadeInDuration = 0
        }
        
        editImageButton.hidden = !appstate.mostRecentlyOpenedHome!.isMyHome()
    }
}

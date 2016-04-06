//
//  SelectStoryblockContentTypeViewController.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 02/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import CTAssetsPickerController

class SelectStoryblockContentTypeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CTAssetsPickerControllerDelegate {
    
    @IBOutlet private weak var selectionView: UIView!
    @IBOutlet private weak var recentImageCollectionView: UICollectionView!
    @IBOutlet private weak var cameraButton: UIButton!
    
    /// Set this to limit selection to a certain type (image / video).
    var mediaType: PHAssetMediaType?
    
    /// Maximum number of images to select. If not set (default), number of images is not limited.
    var maxSelections: Int? = nil

    /// Callback to be called when image(s) were selected.
    var imageCallback: ((images: [UIImage], originalImageAssetUrls: [String]?) -> Void)?
    
    /// Callback to be called when a video was selected.
    var videoCallback: ((videoAssetUrl: NSURL?, error: NSError?) -> Void)?

    /// Snapshotted background (previous view controller)
    private var backgroundView: UIImageView?
    
    /// A view used to dim out the background view
    private var dimmerView: UIView?
    
    /// Most recent pictures, lazy loading result set
    private var fetchResult: PHFetchResult?

    private let window = UIApplication.sharedApplication().keyWindow!
    
    let cellMargin: CGFloat = 3

    // MARK: Private methods
    
    private func dismiss() {
        // Animate the selection view down to the bottom
        UIView.animateWithDuration(0.3, animations: {
            self.selectionView.transform = CGAffineTransformMakeTranslation(0, self.selectionView.bounds.height)
            self.dimmerView?.alpha = 0.0
            }) { finished in
                self.dimmerView?.removeFromSuperview()
                self.navigationController?.popViewControllerAnimated(false)
        }
    }
    
    private func show() {
        dimmerView = UIView(frame: view.frame)
        dimmerView!.backgroundColor = UIColor.blackColor()
        dimmerView!.alpha = 0.0
        view.insertSubview(dimmerView!, belowSubview: selectionView)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(SelectStoryblockContentTypeViewController.dimmerTapped))
        dimmerView!.addGestureRecognizer(tapRecognizer)

        selectionView.transform = CGAffineTransformMakeTranslation(0, selectionView.bounds.height)
        
        // Animate the selection view up from the bottom
        UIView.animateWithDuration(0.3, animations: {
            self.selectionView.transform = CGAffineTransformIdentity
            self.dimmerView?.alpha = 0.8
            }) { finished in
        }
    }

    private func updateRecentPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 30
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        if let mediaType = mediaType {
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", mediaType.rawValue)
        }
      
        fetchResult = PHAsset.fetchAssetsWithOptions(fetchOptions)
        log.debug("Fetched \(fetchResult!.count) most recent media assets")
        
        recentImageCollectionView.reloadData()
    }
    
    // MARK: Public methods
    
    /// Creates an instance of this view controller
    class func create() -> SelectStoryblockContentTypeViewController {
        let controller = NSBundle.mainBundle().loadNibNamed("SelectStoryblockContentTypeViewController", owner: nil, options: nil).first as! SelectStoryblockContentTypeViewController
        
        return controller
    }
    
    // MARK: IBAction handlers
    
    @IBAction private func galleryButtonPressed(button: UIButton) {
        let picker = CTAssetsPickerController()
        picker.title = NSLocalizedString("homestory:photos-and-videos", comment: "")
        picker.delegate = self
        picker.showsEmptyAlbums = false
        
        if let mediaType = mediaType {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "mediaType = %d", mediaType.rawValue)
            picker.assetsFetchOptions = options
        }
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction private func cameraButtonPressed(button: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .Camera;
        if let mediaType = mediaType {
            // Only display media of given type
            imagePicker.mediaTypes = (mediaType == .Image) ? [String(kUTTypeImage)] : [String(kUTTypeMovie)]
        } else {
            // Not limited to a type
            imagePicker.mediaTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        }
        imagePicker.allowsEditing = false
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: Other methods
    
    func dimmerTapped() {
        dismiss()
    }
    
    // MARK: From UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        defer {
            dismissViewControllerAnimated(true, completion: nil)
            dismiss()
        }
        
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String else {
            log.error("Failed to get media type from info dict: \(info)")
            return
        }
        
        if mediaType == kUTTypeImage as String {
            // Picked an image
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                let originalUrl = info[UIImagePickerControllerReferenceURL] as? NSURL
                var originalImageAssetUrls: [String]? = nil
                if originalUrl != nil {
                    originalImageAssetUrls = [originalUrl!.absoluteString]
                }
                self.imageCallback?(images: [pickedImage], originalImageAssetUrls: originalImageAssetUrls)
            }
        } else {
            // Picked a video
            if let selectedVideoAssetUrl = info[UIImagePickerControllerMediaURL] as? NSURL {
                self.videoCallback?(videoAssetUrl: selectedVideoAssetUrl, error: nil)
            }
        }
    }
    
    // MARK: From CTAssetsPickerControllerDelegate
    
    func assetsPickerController(picker: CTAssetsPickerController!, shouldSelectAsset asset: PHAsset!) -> Bool {
        // Only enable 1 video OR multiple images to be selected
        if asset.mediaType == .Video {
            return picker.selectedAssets.count == 0
        }
        
        for anAsset in picker.selectedAssets {
            if anAsset.mediaType == .Video {
                return false
            }
        }
        
        if let maxSelections = maxSelections {
            return picker.selectedAssets.count < maxSelections
        }
        
        return true
    }
    
    func assetsPickerControllerDidCancel(picker: CTAssetsPickerController!) {
        dismissViewControllerAnimated(true, completion: nil)
        dismiss()
    }
    
    func assetsPickerController(picker: CTAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        defer {
            dismissViewControllerAnimated(true, completion: nil)
            dismiss()
        }
        
        var pickedPhotos = [UIImage]()
        var pickedOriginalURLs = [String]()
        var remaining = assets.count
        
        for asset in assets {
            guard let asset = asset as? PHAsset else {
                continue
            }
            
            switch asset.mediaType {
            case .Image:
                requestAssetImage(asset, scaleFactor: 0.6) { image in
                    assert(NSThread.isMainThread(), "Must be called on the main thread")
                    if let image = image {
                        pickedPhotos.append(image)
                        pickedOriginalURLs.append(getJPGAssetUrl(asset))
                    }
                    
                    if --remaining == 0 {
                        self.imageCallback?(images: pickedPhotos, originalImageAssetUrls: pickedOriginalURLs)
                    }
                }
            case .Video:
                requestAssetVideoUrl(asset) { (assetUrl, error) in
                    self.videoCallback?(videoAssetUrl: assetUrl, error: error)
                }
                return
            default:
                break
            }
        }
    }
    
    // MARK: From UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fetchResult != nil) ? fetchResult!.count : 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RecentImageCell", forIndexPath: indexPath) as! RecentImageCell
        
        guard let asset = fetchResult![indexPath.row] as? PHAsset else {
            log.error("Failed to get asset from fetch result!")
            return cell
        }
        
        requestAssetImage(asset, scaleFactor: 0.6) { image in
            cell.image = image
        }
        
        cell.selectedCallback = { image in
            if asset.mediaType == .Video {
                requestAssetVideoUrl(asset) { (assetUrl, error) in
                    runOnMainThread {
                        self.videoCallback?(videoAssetUrl: assetUrl, error: error)
                        self.dismiss()
                    }
                }
            } else {
                if let image = image {
                    runOnMainThread {
                        self.imageCallback?(images: [image], originalImageAssetUrls: [getJPGAssetUrl(asset)])
                        self.dismiss()
                    }
                }
            }
        }
        
        cell.playIconImageView.hidden = (asset.mediaType != .Video)
        
        if indexPath.row == (fetchResult!.count - 1) {
            cell.trailingMargin.constant = cellMargin
        } else {
            cell.trailingMargin.constant = 0
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let cellWidth = (collectionView.width - cellMargin) / 3 // 3 == amount of cells visible
        let cellHeight = collectionView.width / 3
        return CGSizeMake(cellWidth, cellHeight)
    }
        
    // MARK: Lifecycle, etc

    deinit {
        log.debug("Deinitialized.")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        backgroundView!.removeFromSuperview()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        show()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        recentImageCollectionView.backgroundView?.backgroundColor = UIColor.whiteColor()
        recentImageCollectionView.backgroundColor = UIColor.whiteColor()
        
        // Snapshot background view
        backgroundView = UIImageView(frame: window.bounds)
        backgroundView!.image = window.snapshot()
        view.superview?.insertSubview(backgroundView!, belowSubview: view)
        
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(.Camera)
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .NotDetermined:
                log.debug("Access to photos not determined")
            case .Authorized:
                log.debug("Access to photos OK!")
                runOnMainThread {
                    self.updateRecentPhotos()
                }
            case .Restricted:
                log.debug("Access to photos restricted")
            case .Denied:
                log.debug("Access to photos denied")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        recentImageCollectionView.registerNib(UINib(nibName: "RecentImageCell", bundle: nil), forCellWithReuseIdentifier: "RecentImageCell")
    }
}

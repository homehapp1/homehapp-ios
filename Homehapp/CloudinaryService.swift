//
//  CloudStorageService.swift
//  Homehapp
//
//  Created by Lari Tuominen on 31/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import Cloudinary

public protocol CloudinaryServiceDelegate {
    /// Called when all running operations have completed
    func cloudinaryUploadsCompleted()
}

/**
 Provides functionality for uploading media data to a cloud storage.
 Underlying cloud technology is Cloudinary CDN.
*/
public class CloudinaryService {
    private static let singletonInstance = CloudinaryService()
    
    /// Upload response datatype
    typealias UploadResponse = (success: Bool, url: String?, width: Int?, height: Int?)
    
    /// Configuration url
    private let configUrl = "cloudinary://674338823352987:urOckACznNPsN58_1zewwJmasnI@homehapp"
    
    /// Cloudinary API facade
    private var cloudinary: CLCloudinary?
    
    /// Number of all current operations.
    private var ongoingOperationsCount = 0
    
    /// Lock for synchronizing access to ```ongoingOperationsCount```
    private let ongoingOperationsCountLock = ReadWriteLock()
    
    /// Delegates
    private var delegates = [CloudinaryServiceDelegate]()
    
    /// Lock for ```delegates``` list
    private let delegatesLock = ReadWriteLock()
    
    // MARK: Private methods
    
    private func operationStarted() {
        ongoingOperationsCountLock.withWriteLock {
            self.ongoingOperationsCount++
        }
    }
    
    private func operationCompleted() -> Bool {
        return ongoingOperationsCountLock.withWriteLock {
            self.ongoingOperationsCount--

            return (self.ongoingOperationsCount == 0)
        }
    }

    private func notifyDelegatesOperationsCompleted() {
        delegatesLock.withReadLock {
            self.delegates.forEach { $0.cloudinaryUploadsCompleted() }
        }
    }
    
    /// Return Cloudinary public id for the image. Cloudinary public id is the identifier before file ending
    private func getPublicId(url: String) -> String {
        
        var urlWithoutFileFormat = ""
        if url.contains(".jpg") {
            urlWithoutFileFormat = url.split(".jpg")[0]
        } else if url.contains(".mp4") {
            urlWithoutFileFormat = url.split(".mp4")[0]
        }
        
        let urlParts = urlWithoutFileFormat.split("/")
        let publicId = urlParts[urlParts.count - 1]
        return publicId
    }
    
    // MARK: Public methods
    
    /// Returns a shared (singleton) instance.
    class func sharedInstance() -> CloudinaryService {
        return singletonInstance
    }

    /// Adds a delegate. You must remember to call removeDelegate().
    func addDelegate<T where T: CloudinaryServiceDelegate, T: Equatable>(delegate: T) {
        delegatesLock.withWriteLock {
            self.delegates.append(delegate)
        }
    }
    
    /// Removes a delegate
    func removeDelegate<T where T: CloudinaryServiceDelegate, T: Equatable>(delegate: T) {
        delegatesLock.withWriteLock {
            for (index, object) in self.delegates.enumerate() {
                if let delegateObject = object as? T where delegateObject == delegate {
                    self.delegates.removeAtIndex(index)
                }
            }
        }
    }
    
    /// Uploads an image to the cloud storage.
    func uploadImage(image: UIImage, progressCallback: (Float -> Void), completionCallback: (UploadResponse -> Void)) {
        if let imageData = UIImageJPEGRepresentation(image, 0.9) {
            uploadImage(imageData, progressCallback: progressCallback, completionCallback: completionCallback)
        }
    }
    
    private func uploadImage(imageData: NSData, progressCallback: (Float -> Void), completionCallback: (UploadResponse -> Void)) {
        log.verbose("Starting Cloudinary image upload..")
        
        // TODO should we do uploader per upload?
        let uploader = CLUploader(cloudinary, delegate: nil)
        let options = ["tags": "ios_upload"]
        
        operationStarted()
        
        uploader.upload(imageData, options: options, withCompletion: { (successResult, errorResult, code, context) -> Void in
            log.debug("Image upload completed, successResult: \(successResult), errorResult: \(errorResult), code: \(code)")
            if let url = successResult?["url"] as? String,
                width = successResult?["width"] as? Int,
                height = successResult?["height"] as? Int {
                    completionCallback((success: true, url: url, width: width, height: height))
            } else {
                let allCompleted = self.operationCompleted()
                completionCallback((success: false, url: nil, width: nil, height: nil))
                if allCompleted {
                    self.notifyDelegatesOperationsCompleted()
                }
            }
            }, andProgress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, context) -> Void in
                log.verbose("Upload progress: \(totalBytesWritten) / \(totalBytesExpectedToWrite)")
                progressCallback(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
        })

    }
    
    /**
     Uploads a video to the cloud storage.
     
     - returns: true if the download started ok, false if there were errors
     */
    func uploadVideo(videoMediaUrl: String, progressCallback: (Float -> Void), completionCallback: (UploadResponse -> Void)) -> Bool {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        log.verbose("Starting Cloudinary video upload - media URL: \(videoMediaUrl)")
        let uploader = CLUploader(cloudinary, delegate: nil)
        
        // Video is sent as 720p
        let transformation: CLTransformation = CLTransformation()
        transformation.width = 1280;
        transformation.height = 720;
        transformation.crop = "fill";
        transformation.videoCodec = "mp4"
        
        let options = [
            "tags": "ios_upload", "resource_type": "video",
            "eager": [
                transformation
            ],
            "eager_async": true,
            "format": "mp4"
        ]
        
        operationStarted()
        
        log.debug("Starting Cloudinary uploader..")
        uploader.upload((videoMediaUrl as NSString), options: options, withCompletion: { (successResult, errorResult, code, context) in
            log.debug("Video upload completed, successResult: \(successResult), errorResult: \(errorResult), code: \(code)")
            let allCompleted = self.operationCompleted()
            
            if let url = successResult?["url"] as? String,
                width = successResult?["width"] as? Int,
                height = successResult?["height"] as? Int {
                    completionCallback((success: true, url: url, width: width, height: height))
                    remoteService.prewarmVideo(url)
            } else {
                completionCallback((success: false, url: nil, width: nil, height: nil))
            }
            
            if allCompleted {
                self.notifyDelegatesOperationsCompleted()
            }
            }, andProgress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, context) -> Void in
                log.verbose("Upload progress: \(totalBytesWritten) / \(totalBytesExpectedToWrite)")
                progressCallback(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
        })
        
        return true
    }
    
    /// Upload all the images and videos to server where local = true
    func uploadUnsentImages() {
        do {
            let imageResults = try dataManager.listUnsetImages()
            log.debug("Found \(imageResults.count) images unsent")
            for image in imageResults {
                if let localFileURL = image.localUrl, fileUrl =  NSURL(string: localFileURL) {
                    requestImageDataForAssetUrl(fileUrl, callback: { [weak self] (imageData) -> Void in
                        let scaledImage = UIImage(data: imageData)?.scaleDown(maxSize: CGSizeMake(CGFloat(image.width), CGFloat(image.height)))
                        if let imageToUpload = scaledImage {
                            self?.uploadImage(imageToUpload, progressCallback: { (progress) -> Void in
                                }, completionCallback: {(success: Bool, url: String?, width: Int?, height: Int?) -> Void in
                                    if success && url != nil {
                                        
                                        // Remove the original local image from the cache
                                        ImageCache.sharedInstance().removeImage(url: image.url, removeFromDisk: true)
                                        
                                        dataManager.performUpdates {
                                            // Image is now uploaded; mark it no longer local + update to remote url
                                            image.url = url!
                                            image.local = false
                                            image.uploadProgress = 1.0
                                        }
                                        
                                        // Start fetching the (scaled) remote images
                                        ImageCache.sharedInstance().getImage(url: image.scaledUrl, loadPolicy: .Network)
                                        
                                        // TODO define which one to send to server while images uploaded and do not send all
                                        remoteService.updateMyHomeOnServer()
                                        if let home = dataManager.findMyHome() {
                                            if home.neighborhood != nil {
                                                remoteService.updateMyNeighborhood(home.neighborhood!)
                                            }
                                        }
                                        remoteService.updateCurrentUserOnServer()
                                    }
                            })
                        }
                        
                    })
                }
            }
        } catch let error {
            log.error("Error fetching unset images: \(error)")
        }
    }

    /// Remove Image or Video from Cloudinary based on it's url
    func removeAsset(url: String, type: String) {
        
        // Obtain asset public id from url
        let publicId = getPublicId(url)
        
        let uploader = CLUploader(cloudinary, delegate: nil)
        
        // Destroy image from Cloudinary and all it's derivatives
        uploader.destroy(publicId, options: ["resource_type" : type])
    }
    
    func removeAssetsFromStoryBlock(storyBlock: StoryBlock) {
        if let image = storyBlock.image {
            removeAsset(image.url, type: "image")
        }
        
        if let video = storyBlock.video {
            removeAsset(video.url, type: "video")
        }
    }
    
    // MARK: Lifecycle etc
    
    init() {
        cloudinary = CLCloudinary(url: configUrl)
    }
}

//
//  Utils.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 25/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import Photos

import QvikNetwork
import QvikSwift

let HHUtilsErrorDomain = "HHUtilsErrorDomain"
let HHUtilsVideoEncodeFailed = -100
let HHUtilsCouldNotGetAssetURL = -101

/**
 Calculates the required downscale ratio for an image in a way that the 
 image returned from Cloudinary is not larger than the max image size set to 
 ImageCache's shared instance.
 
 If the max size is not defined or the image is already smaller, the original url is returned.
 
 Getting a scaled version of a cloudinary image url is to add width parameter as such: 

 http://res.cloudinary.com/demo/image/upload/w_0.6/sample.jpg
*/
func scaledCloudinaryUrl(width width: Int, height: Int, url: String) -> String {
    guard let maxSize = ImageCache.sharedInstance().maximumImageDimensions else {
        return url
    }
    
    let width = CGFloat(width)
    let height = CGFloat(height)
    
    if (width < maxSize.width) && (height < maxSize.height) {
        
        // Let's always make sure exif information and orientation considered if we dont't scale image in cloudinary
        let scaledUrl = url.stringByReplacingOccurrencesOfString("/upload/", withString: "/upload/a_exif")
        
        return scaledUrl
    }

    let widthRatio = width / maxSize.width
    let heightRatio = height / maxSize.height
    let scale = 1.0 / max(widthRatio, heightRatio)
    let scaleFormat = "w_\(scale)"
    let scaledUrl = url.stringByReplacingOccurrencesOfString("/upload/", withString: "/upload/\(scaleFormat)/")
    
    return scaledUrl
}

/// Return scaled Cloudinary url for home cover images in main list and home story header
func scaledCloudinaryCoverImageUrl(width width: Int, height: Int, url: String) -> String {
    
    let width = CGFloat(width)
    let height = CGFloat(height)
    
    let screenBounds = UIScreen.mainScreen().bounds
    let screenScale = UIScreen.mainScreen().scale
    let screenPixels = CGSizeMake(screenBounds.size.width * screenScale, max(1000, screenBounds.size.height * screenScale));
    
    if (width < screenPixels.width) && (height < screenPixels.height) {
        return url
    }
    
    let widthRatio = width / screenPixels.width
    let heightRatio = height / screenPixels.height
    let scale = 1.0 / max(widthRatio, heightRatio)
    let scaleFormat = "w_\(scale)"
    let scaledUrl = url.stringByReplacingOccurrencesOfString("/upload/", withString: "/upload/\(scaleFormat)/")
    
    return scaledUrl
}

/// Returns a snapshot image for a local video asset, taken as a snapshot from the start of the video
func getVideoSnapshot(videoUrl: NSURL) -> UIImage? {
    do {
        let asset = AVURLAsset(URL: videoUrl, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let cgImage = try imgGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
        
        return UIImage(CGImage: cgImage)
    } catch let error {
        log.debug("Failed to get snapshot for video; error: \(error)")
        return nil
    }
}

/**
 Asynchronously get downsampled video data from an AVAssetExportSession.
 The caller should delete the file at videoFileUrl once it is no longer needed.
 The callback will be called on the main thread.
*/
private func requestVideoDataForExportSession(exportSession: AVAssetExportSession, callback: ((videoFileUrl: NSURL?, error: NSError?) -> Void)) {
    let startTime = NSDate()
    
    // Allocate a temporary file to write to
    let tempFilePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(NSUUID().UUIDString)
    
    // Configure the export session
    exportSession.canPerformMultiplePassesOverSourceMediaData = true
    exportSession.outputFileType = AVFileTypeMPEG4
    exportSession.outputURL = NSURL(fileURLWithPath: tempFilePath)
    
    exportSession.exportAsynchronouslyWithCompletionHandler() {
        log.debug("Video export completed, status: \(exportSession.status), error: \(exportSession.error)")
        
        if exportSession.status == .Completed {
            log.debug("Video encoding OK, the process took \(-startTime.timeIntervalSinceNow) seconds")
            
            runOnMainThread {
                // Callback on main thread
                callback(videoFileUrl: exportSession.outputURL, error: nil)
            }
        } else {
            runOnMainThread {
                // Callback on main thread
                if let error = exportSession.error {
                    callback(videoFileUrl: nil, error: error)
                } else {
                    callback(videoFileUrl: nil, error: NSError(domain: HHUtilsErrorDomain, code: HHUtilsVideoEncodeFailed, userInfo: nil))
                }
            }
        }
    }
}

/** 
 Asynchronously get downsampled video data for a AVAsset url.
 The caller should delete the file at videoFileUrl once it is no longer needed.
 The callback will be called on the main thread.
*/
func requestVideoDataForAssetUrl(url: NSURL, callback: ((videoFileUrl: NSURL?, error: NSError?) -> Void)) {
    let asset = AVAsset(URL: url)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
        callback(videoFileUrl: nil, error: NSError(domain: HHUtilsErrorDomain, code: HHUtilsVideoEncodeFailed, userInfo: nil))
        return
    }
    
    requestVideoDataForExportSession(exportSession, callback: callback)
}

/** 
 Asynchronously get image data for AVAsset url.
 The callback will be called on the main thread.
*/
func requestImageDataForAssetUrl(url: NSURL, callback: ((imageData: NSData) -> Void)) {
    let fetchResult = PHAsset.fetchAssetsWithALAssetURLs([url], options: nil)
    if let phAsset = fetchResult.firstObject as? PHAsset {
        PHImageManager.defaultManager().requestImageDataForAsset(phAsset, options: nil) {
            (imageData, dataURI, orientation, info) -> Void in
            if let data = imageData {
                runOnMainThread {
                    callback(imageData: data)
                }
            }
        }
    }
}


/** 
 Asynchronously gets an asset url for a video
 The callback will be called on the main thread.
*/
func requestAssetVideoUrl(asset: PHAsset, callback: (assetUrl: NSURL?, error: NSError?) -> Void) {
    let options = PHVideoRequestOptions()
    options.deliveryMode = .HighQualityFormat
    
    // enable access to iCloud if video is only there
    options.networkAccessAllowed = true
    
    PHImageManager.defaultManager().requestAVAssetForVideo(asset, options: options) { (avAsset, avAudioMix, info) in
        runOnMainThread {
            if let urlAsset = avAsset as? AVURLAsset {
                callback(assetUrl: urlAsset.URL, error: nil)
            } else {
                callback(assetUrl: nil, error: NSError(domain: HHUtilsErrorDomain, code: HHUtilsCouldNotGetAssetURL, userInfo: nil))
            }
        }
    }
}

/// Asynchronously gets an UIImage out of a PHAsset object
func requestAssetImage(asset: PHAsset, scaleFactor: CGFloat = 1.0, callback: ((image: UIImage?) -> Void)) {
    let options = PHImageRequestOptions()
    options.resizeMode = PHImageRequestOptionsResizeMode.Exact;
    options.version = PHImageRequestOptionsVersion.Current;
    options.networkAccessAllowed = true
    
    let targetSize = CGSize(width: scaleFactor * CGFloat(asset.pixelWidth), height: scaleFactor * CGFloat(asset.pixelHeight))

    PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: targetSize, contentMode: .AspectFit, options: options,
        resultHandler: {(image, info) in
            if let isDegraded = info?[PHImageResultIsDegradedKey] as? NSNumber where isDegraded.boolValue {
                // This is a temporary image; skip it
                return
            }
            
            if image == nil {
                if let error = info?[PHImageErrorKey] as? NSError {
                    log.error("Failed to extract UIImage out of PHAsset, error: \(error)")
                }
            }
            
            runOnMainThread {
                callback(image: image)
            }
    })
}

/**
 Get JPG assets-library-url for given asset
 http://stackoverflow.com/questions/28887638/how-to-get-an-alasset-url-from-a-phasset
 */
func getJPGAssetUrl(asset: PHAsset) -> String {
    return "assets-library://asset/asset.JPG?id=\(asset.localIdentifier.substring(startIndex: 0, length: 36))&ext=JPG"
}

/// Make a shallow copy of a CachedImageView
func copyCachedImageView(source: CachedImageView) -> CachedImageView {
    let imageView = CachedImageView(frame: source.frame)
    imageView.contentMode = source.contentMode
    imageView.transform = source.transform
    imageView.thumbnailData = source.thumbnailData
    imageView.fadeInColor = source.fadeInColor
    imageView.imageCache = source.imageCache
    imageView.image = source.image
    imageView.imageUrl = source.imageUrl
    
    return imageView
}

/// Returns a (default) localized error message for a remote response
func localizedErrorMessage(response: RemoteResponse) -> String? {
    if response.success {
        return nil
    } else {
        guard let remoteError = response.remoteError else {
            log.error("remoteError not set!")
            assert(false, "remoteError not set!")
            return nil
        }
        
        switch remoteError {
        case .NetworkError:
            return NSLocalizedString("errormsg:network", comment: "")
        case .NetworkTimeout:
            return NSLocalizedString("errormsg:network-timeout", comment: "")
        default:
            return NSLocalizedString("errormsg:server", comment: "")
        }
    }
}

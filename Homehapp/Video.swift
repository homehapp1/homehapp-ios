//
//  Video.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 22/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift

class Video: DeletableObject {
    dynamic var width: Int = 0
    dynamic var height: Int = 0
    dynamic var url: String = ""
    dynamic var local: Bool = false // true if not yet uploaded from this device
    dynamic var thumbnailData: NSData? = nil
    dynamic var uploadProgress: Float = 1.0 // upload progress value from 0 .... 1 when user uploads video

    /// Returns the thumbnail image url for this video; for Cloudinary videos, form url by replacing .mov by .jpg.
    /// For local videos, use the video asset url; this requires the thumbnail to be placed into the image cache by that url.
    var thumbnailUrl: String? {
        return local ? url : ((url as NSString).stringByDeletingPathExtension as NSString).stringByAppendingPathExtension("jpg")
    }
    
    /// Returns a scaled (cloudinary) url. For local ones, returns the url itself.
    var scaledThumbnailUrl: String? {
        if let thumbnailUrl = thumbnailUrl {
            return local ? thumbnailUrl : scaledCloudinaryUrl(width: width, height: height, url: thumbnailUrl)
        } else {
            return nil
        }
    }
    
    /// Return 720p scaled version of the video from Cloudinary
    var scaledVideoUrl: String {
        if width >= height {
            return url.stringByReplacingOccurrencesOfString("/upload", withString: "/upload/c_fill,h_720,w_1280")
        } else {
            return url.stringByReplacingOccurrencesOfString("/upload", withString: "/upload/c_fill,h_1280,w_720")    
        }
    }

    convenience init(url: String, width: Int, height: Int, local: Bool = false) {
        self.init()
        
        self.url = url
        self.width = width
        self.height = height
        self.local = local
    }
    
    override static func indexedProperties() -> [String] {
        return ["deleted"]
    }
}

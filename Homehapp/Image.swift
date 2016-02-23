//
//  Image.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 22/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift

class Image: DeletableObject {
    dynamic var width: Int = 0
    dynamic var height: Int = 0
    dynamic var url: String = ""
    dynamic var local: Bool = false // true if not yet uploaded from this device
    dynamic var thumbnailData: NSData? = nil
    dynamic var localUrl: String? = nil
    dynamic var uploadProgress: Float = 1.0 // upload progress value from 0 .... 1 when user uploads image
    
    /// Returns a scaled (cloudinary) url. For local ones, returns the url itself.
    var scaledUrl: String {
        return local ? url : scaledCloudinaryUrl(width: width, height: height, url: url)
    }
    
    convenience init(url: String, width: Int, height: Int, local: Bool = false, localUrl: String?) {
        self.init()
        
        self.url = url
        self.width = width
        self.height = height
        self.local = local
        self.localUrl = localUrl
    }
    
    override static func indexedProperties() -> [String] {
        return ["deleted"]
    }
    
    func toJSON() -> [String: AnyObject] {
        var imageJson: [String: AnyObject] = [
            "url": url,
            "width": width,
            "height": height
        ]
        
        if let thumbnailData = thumbnailData {
            imageJson["thumbnail"] = ["data": thumbnailData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())]
        }
        
        return imageJson
    }
    
    /// Return true if image is wider than tall
    func isLandscape() -> Bool {
        return width >= height
    }
    
    static func fromJSON(imageJsonObject: AnyObject?) -> Image? {
        if let imageJson = imageJsonObject as? NSDictionary,
            width = imageJson["width"] as? Int,
            height = imageJson["height"] as? Int,
            url = imageJson["url"] as? String {
                let image = Image(url: url, width: width, height: height, localUrl: nil)
                
                if let thumbnailDataBase64 = imageJson["thumbnail"]?["data"] as? String {
                    image.thumbnailData = NSData(base64EncodedString: thumbnailDataBase64, options: NSDataBase64DecodingOptions())
                }
                
                return image
        }
        
        return nil
    }
}

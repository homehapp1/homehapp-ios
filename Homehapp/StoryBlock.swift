//
//  StoryBlock.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import RealmSwift

/// Model file for a story block 
class StoryBlock: DeletableObject {
    enum Template : String {
        case ContentBlock = "ContentBlock"
        case ContentImage = "ContentImage"
        case BigVideo = "BigVideo"
        case Gallery = "Gallery"
    }
    
    enum Layout : String {
        case Title = "Title"
        case TitleAndBody = "TitleAndBody"
        case Body = "Body"
    }
    
    dynamic var title: String? = nil
    dynamic var mainText: String? = nil
    dynamic var imageAlign: String? = nil
    dynamic var template: String = ""
    dynamic var layoutRaw: String?
    dynamic var image: Image? = nil
    dynamic var video: Video? = nil
    dynamic var videoUrl: String?
    let galleryImages = List<Image>()

    var layout: Layout {
        get {
            if let layoutRaw = layoutRaw, myLayout = Layout(rawValue: layoutRaw) {
                return myLayout
            } else {
                if title != nil && title?.length > 0 {
                    return Layout.TitleAndBody
                } else {
                    return Layout.Body
                }
            }
        }
        
        set {
            layoutRaw = newValue.rawValue
        }
    }
    
    convenience init(template: Template) {
        self.init()
        
        self.template = template.rawValue
    }
    
    override static func indexedProperties() -> [String] {
        return ["deleted"]
    }
}


//
//  ShareController.swift
//  Homehapp
//
//  Created by Tuukka Puumala on 3.12.2015.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import RealmSwift

class ShareController: UIActivityViewController {
    
    private var home : Home!
    weak var parentController: UIViewController?
    
    class func newController(home: Home) -> ShareController {
        let text = getShareText(home)
        let shareUrl = NSURL(string: getShareUrlString(home))!
        let controller = ShareController(activityItems: [text, shareUrl], applicationActivities: nil)
        controller.home = home
        return controller
    }

    // MARK: - Private functions
    
    private static func getShareUrlString(home: Home) -> String {
        return "https://homehapp.com/homes/" + home.slug
    }
    
    private static func getShareText(home: Home) -> String {
        return home.title
    }
    
}

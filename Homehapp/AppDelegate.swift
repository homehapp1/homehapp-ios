
//
//  AppDelegate.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import XCGLogger
import FBSDKLoginKit
import Fabric
import Crashlytics
import GoogleMaps

// Global singletons
let log = XCGLogger(identifier: "HOMEHAPP")
let remoteService = RemoteService.sharedInstance()
let appstate = AppState.sharedInstance()
let dataManager = DataManager.sharedInstance()
let cloudStorage = CloudinaryService.sharedInstance()
let authService = AuthenticationService.sharedInstance()
let locationService = LocationService.sharedInstance()

// Global constants
let thumbHeaderDataTypeIOSJPEG: UInt8 = 0x01
let thumbHeaderDataTypeCanvasJPEG: UInt8 = 0x02
let jpegThumbCompressionQuality: CGFloat = 0.3
let jpegThumbPixelBudget: Int = (50 * 50)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CloudinaryServiceDelegate {

    var window: UIWindow?

    // MARK: Private methods
    
    private func setupAppearance() {
        // Set the application window's background color to white
        window?.backgroundColor = UIColor.whiteColor()
        UINavigationBar.appearance().tintColor = UIColor.blackColor()
        UITabBar.appearance().tintColor = UIColor(red: 184.0/255.0, green: 129.0/255.0, blue: 80.0/255.0, alpha: 1.0)
        UITextView.appearance().tintColor = UIColor.homehappDarkColor()
        UITextField.appearance().tintColor = UIColor.homehappDarkColor()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        #if DEBUG // Debug configuration
            log.setup(.Debug, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLogLevel: nil)
        #else // Release configuration
            log.setup(.Info, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLogLevel: nil)            
        #endif
        
        // Init Google analytics
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true
        
        // Init Fabric Crashlytics for crash gathering tool
        Fabric.with([Crashlytics.self])
        
        // Define maximum size of images we fetch from cloudinary
        ImageCache.sharedInstance().maximumImageDimensions = CGSize(width: 1500, height: 1000)
        
        // Configure global UI appearance
        setupAppearance()
        
        // Init Google login
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Init Google maps
        GMSServices.provideAPIKey("AIzaSyCqsUS5yEkfxdsVz3663XABCJ8QMUKupTE")
        
        // Start listening to Cloudinary Service events
        //NOTE this will cause "my home" to be sent to the server; do we want this to happen automatically or not?
//        cloudStorage.addDelegate(self)
        
        // Initialize iOS JPEG headers for thumbnailization
        do {
            guard let filePath = NSBundle.mainBundle().pathForResource("ios-jpegheader-q30", ofType: "data"),
                jpegHeaderData = NSData(contentsOfFile: filePath) else {
                    log.error("Missing iOS JPEG header data in bundle!")
                    assert(false)
                    return false
            }
            registerJpegThumbnailHeader(dataType: thumbHeaderDataTypeIOSJPEG, headerData: jpegHeaderData)
        }
        
        do {
            // Initialize Canvas JPEG headers for thumbnailization
            guard let filePath = NSBundle.mainBundle().pathForResource("canvas-jpegheader", ofType: "data"),
                jpegHeaderData = NSData(contentsOfFile: filePath) else {
                    log.error("Missing 'canvas-jpegheader.data' in bundle!")
                    assert(false)
                    return false
            }
            registerJpegThumbnailHeader(dataType: thumbHeaderDataTypeCanvasJPEG, headerData: jpegHeaderData)
        }
        
        // Application hooks with FB login
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
            let googleUrlHandled = GIDSignIn.sharedInstance().handleURL(url,
                sourceApplication: sourceApplication,
                annotation: annotation)
            
            if googleUrlHandled {
                return true
            } else {
                return FBSDKApplicationDelegate.sharedInstance().application(
                    application,
                    openURL: url,
                    sourceApplication: sourceApplication,
                    annotation: annotation)
            }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        remoteService.sendAllUpdatesToServer(false)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        remoteService.fetchHomes()
        cloudStorage.uploadUnsentImages()
        cloudStorage.uploadUnsentVideos()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        // Stop listening to Cloudinary Service events
        cloudStorage.removeDelegate(self)
    }
    
    // MARK: From CloudinaryServiceDelegate
    
    func cloudinaryUploadsCompleted() {
        log.debug("Cloudinary uploads completed! Updating My Home object to server..")
        remoteService.updateMyHomeOnServer()
    }
}


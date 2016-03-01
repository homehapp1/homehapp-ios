platform :ios, '8.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'

pod 'Alamofire', '~> 2.0'
pod 'Reveal-iOS-SDK', :configurations => ['Debug']
pod 'XCGLogger', '~> 3.0'
pod 'RealmSwift', '0.96.2'
pod 'SwiftKeychain', '~> 0.1'
pod 'CryptoSwift'
pod 'SwiftDate'
pod 'CTAssetsPickerController',  '~> 3.1.0'
pod 'Cloudinary'
pod 'FBSDKCoreKit'
pod 'FBSDKLoginKit'
pod 'FBSDKShareKit'
pod 'Google/SignIn'
pod 'Google/Analytics'
pod 'Fabric'
pod 'Crashlytics'
pod 'GoogleMaps'

# For generating the Acknowledgements: https://github.com/CocoaPods/CocoaPods/wiki/Acknowledgements
post_install do | installer |
require 'fileutils'
FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Homehapp/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end


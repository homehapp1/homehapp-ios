platform :ios, '8.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://git.qvik.fi/pods/QvikPodSpecs.git'

pod 'Alamofire', '~> 2.0'
pod 'Reveal-iOS-SDK', :configurations => ['Debug']
pod 'XCGLogger', '~> 3.0'
pod 'SwiftKeychain'
pod 'RealmSwift', '0.96.2' 
pod 'QvikSwift', '~> 2.0.0'
#pod 'QvikSwift', :path => '../qvik-swift-ios/'
pod 'QvikNetwork'
#pod 'QvikNetwork', :path => '../qvik-network-ios/'
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

# For generating the Acknowledgements
post_install do | installer |
require 'fileutils'
FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Homehapp/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

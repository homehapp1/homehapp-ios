//
//  LoginViewController.swift
//  Homehapp
//
//  Created by Tuukka Puumala on 26.11.2015.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Onboard

let loginSuccessNotification = "loginSuccessNotification"

class LoginViewController: BaseViewController, GIDSignInUIDelegate, GIDSignInDelegate {

    @IBOutlet weak var fbLoginButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var googleLoginButton: UIButton!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var termsButton: UIButton!
    
    @IBOutlet weak var background : UIImageView!
    @IBOutlet weak var contentArea: UIView!
    
    @IBOutlet var defaultConstraints: [NSLayoutConstraint]!
    @IBOutlet var startConstraints: [NSLayoutConstraint]!
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var tagLine: UILabel!
    
    private var onboardingViewController: OnboardingViewController? = nil
    
    private let profileImageWidth = 160
    
    // MARK: - Private
    
    private func getFacebookUserData(token: FBSDKAccessToken) {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email,name"])
        graphRequest.startWithCompletionHandler({ [weak self] (connection, result, error) -> Void in
            if error != nil {
                // Process error
                log.debug("Error: \(error)")
            } else {
                log.debug("fetched user: \(result)")
                
                authService.registerOrLoginUser(
                    UserLoginData(
                        id: token.userID,
                        token: token.tokenString,
                        email: result.valueForKey("email") as! String,
                        displayName: result.valueForKey("name") as! String,
                        service: .Facebook
                    )
                ) { (session, error) -> Void in
                    if error == nil {
                        if let strongSelf = self {
                            if let firstName = session!.valueForKey("user")!.valueForKey("firstName"), lastName = session!.valueForKey("user")!.valueForKey("lastName") {
                                strongSelf.welcomeText.text = "\(firstName) \(lastName)"
                            }
                            strongSelf.preloadFacebookProfileImage(token.userID)
                            strongSelf.exitView(2)
                        }
                    } else {
                        self?.showLoginFailedMessage(NSLocalizedString("loginviewcontroller:login-failed-title", comment: ""), message: NSLocalizedString("loginviewcontroller:login-failed-message", comment: ""))
                    }
                }
            }
        })
    }
    
    /// Display alert message to user if login failed
    private func showLoginFailedMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    /// Load user avatar image from Facebook, store it to user and send to server
    private func preloadFacebookProfileImage(fbUserId: String) {
        let facebookProfileImageUrl = "http://graph.facebook.com/\(fbUserId)/picture?type=large"
        let currentUser = dataManager.findCurrentUser()
        let profileImage = Image(url: facebookProfileImageUrl, width: profileImageWidth, height: profileImageWidth, localUrl: nil)
        dataManager.performUpdatesInRealm { realm in
            currentUser?.profileImage?.deleted = true
            realm.add(profileImage)
            currentUser?.profileImage = profileImage
        }
        ImageCache.sharedInstance().getImage(url: facebookProfileImageUrl, loadPolicy: .Network);
        remoteService.updateCurrentUserOnServer()
    }
    
    /// Load user avatar image from Google, store in to user and send to server
    private func preloadGoogleProfileImage() {
        if GIDSignIn.sharedInstance().currentUser.profile.hasImage {
            let dimension = UInt(CGFloat(profileImageWidth) * UIScreen.mainScreen().scale)
            if let imageURL = GIDSignIn.sharedInstance().currentUser.profile.imageURLWithDimension(dimension) {
                let profileImage = Image(url: imageURL.absoluteString, width: profileImageWidth, height: profileImageWidth, localUrl: nil)
                let currentUser = dataManager.findCurrentUser()
                dataManager.performUpdatesInRealm { realm in
                    currentUser?.profileImage?.deleted = true
                    realm.add(profileImage)
                    currentUser?.profileImage = profileImage
                }
                ImageCache.sharedInstance().getImage(url: imageURL.absoluteString, loadPolicy: .Network);
                remoteService.updateCurrentUserOnServer()
            }
        }
    }
    
    private func exitView(delay: NSTimeInterval = 0.0) {
        
        //Inform main view about successful login
        NSNotificationCenter.defaultCenter().postNotificationName(loginSuccessNotification, object: nil)
        
        UIView.animateWithDuration(0.4, delay: delay, options: UIViewAnimationOptions(rawValue:0), animations: { () -> Void in
                self.view.alpha = 0.0
            }) { (finished) -> Void in
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
        }
    }
    
    private func showOnboarding() {
        let firstPage = OnboardingContentViewController(title: "", body: NSLocalizedString("onboarding:1", comment: ""), image: UIImage(named: "onboarding_write"), buttonText: "") { () -> Void in }

        let secondPage = OnboardingContentViewController(title: "", body: NSLocalizedString("onboarding:2", comment: ""), image: UIImage(named: "onboarding_heart"), buttonText: "") { () -> Void in }

        let thirdPage = OnboardingContentViewController(title: "", body: NSLocalizedString("onboarding:3", comment: ""), image: UIImage(named: "onboarding_homehapp"), buttonText: "Sign in!") { () -> Void in
        
            UIView.animateWithDuration(0.5, animations: {
                self.onboardingViewController?.view.alpha = 0
                }, completion: { finished in
                    appstate.onboardingShown = "true"
                    self.onboardingViewController?.view.removeFromSuperview()
            })
            
        }
            
        onboardingViewController = OnboardingViewController(backgroundImage: UIImage(named: "onboarding_background"), contents: [firstPage, secondPage, thirdPage])
        
        onboardingViewController!.topPadding = self.view.height / 2 - 100
        onboardingViewController!.underTitlePadding = 40;
        onboardingViewController!.bodyFontSize = 21;
        onboardingViewController!.fontName = "Roboto";
        onboardingViewController!.shouldMaskBackground = false;
        onboardingViewController!.fadePageControlOnLastPage = true
        onboardingViewController!.bottomPadding = 30;
        onboardingViewController!.shouldFadeTransitions = true

        self.view.addSubview(onboardingViewController!.view)
        onboardingViewController?.view.alpha = 0
        
        UIView.animateWithDuration(0.5, animations: {
            self.onboardingViewController?.view.alpha = 1.0
            }, completion: { finished in
                self.logo.hidden = false
                self.tagLine.hidden = false
                self.showLoginContainer()
        })
        
    }

    // MARK: - IBOutlets
    
    @IBAction func facebookLoginTapped(sender: UIButton) {
        let loginManager = FBSDKLoginManager()
        let permissions = ["public_profile", "email"]
        loginManager.logInWithReadPermissions(permissions, fromViewController: self, handler: { (loginResult, error) -> Void in
            
            if error != nil {
                log.error("Failed to login: \(error)")
                self.showLoginFailedMessage(NSLocalizedString("loginviewcontroller:fb-login-failed-title", comment: ""), message: NSLocalizedString("loginviewcontroller:fb-login-failed-message", comment: ""))
            } else if loginResult.isCancelled {
                log.debug("Facebook login was cancelled")
            } else {
                // If you ask for multiple permissions at once, you
                // should check if specific permissions missing
                if loginResult.grantedPermissions.contains("email") {
                    self.getFacebookUserData(loginResult.token)
                }
            }
        })
    }
    
    @IBAction func googleLoginTapped(sender: UIButton) {
        GIDSignIn.sharedInstance().signIn();
    }
    
    @IBAction func withoutLoginTapped(sender: UIButton) {
        self.exitView()
    }
    
    @IBAction func termsTapped(sender: UIButton) {
        let url = NSURL(string: "https://homehapp.com/terms")!
        UIApplication.sharedApplication().openURL(url)
    }
    
    
    // MARK: - Google GIDSignInUI Delegate
    
    func signInWillDispatch(signIn: GIDSignIn!, error: NSError!) {
        log.debug("signInWillDispatch \(signIn)")
    }
    
    /// Present a view that prompts the user to sign in with Google
    func signIn(signIn: GIDSignIn!,
        presentViewController viewController: UIViewController!) {
            self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    // Dismiss the "Sign in with Google" view
    func signIn(signIn: GIDSignIn!,
        dismissViewController viewController: UIViewController!) {
            self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Google GIDSignIn Delegate
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if error == nil {
            authService.registerOrLoginUser(
                UserLoginData(
                    id: user.userID,
                    token: user.authentication.idToken,
                    email: user.profile.email,
                    displayName: user.profile.name,
                    service: .Google
                )
            ) { [weak self] (session, error) -> Void in
                if error == nil {
                    if let strongSelf = self {
                        if let firstName = session!.valueForKey("user")!.valueForKey("firstName"), lastName = session!.valueForKey("user")!.valueForKey("lastName") {
                            strongSelf.welcomeText.text = "\(firstName) \(lastName)"
                        }
                        strongSelf.preloadGoogleProfileImage()
                        strongSelf.exitView(2)
                    }
                } else {
                    self?.showLoginFailedMessage(NSLocalizedString("loginviewcontroller:login-failed-title", comment: ""), message: NSLocalizedString("loginviewcontroller:login-failed-message", comment: ""))
                }
            }
        } else {
            log.debug("\(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!, withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.welcomeText.text = nil
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        if appstate.onboardingShown == nil {
            logo.hidden = true
            tagLine.hidden = true
        }
        
    }
    
    private func setStartConstraint(start: Bool) {
        for constraint in self.startConstraints {
            constraint.active = start
        }
        for constraint in self.defaultConstraints {
            constraint.active = !start
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if appstate.onboardingShown != nil {
            showLoginContainer()
        } else {
            showOnboarding()
        }
    }
    
    private func showLoginContainer() {
        self.view.layoutIfNeeded()
        self.setStartConstraint(false)
        UIView.animateWithDuration(0.4) {
            self.view.layoutIfNeeded()
        }
    }

}

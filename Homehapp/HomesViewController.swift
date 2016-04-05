//
//  ViewController.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 15/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import RealmSwift

private class HomeStoryItem {
    var home: Home?
    var isMyHomeCell = false
    
    init(home: Home) {
        self.home = home
    }
    
    init(home: Home?, isMyHomeCell: Bool) {
        self.isMyHomeCell = isMyHomeCell
        self.home = home
    }
}

/**
Displays the list of homes.
*/
class HomesViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, HomeListLayoutDelegate {
    private let segueIdHomesToHomeStory = "HomesToHomeStory"
    private let segueIdHomesToProfile = "HomesToProfile"

    @IBOutlet private weak var collectionView: UICollectionView!

    /// Custom navigation bar view. Accessible from outside for use in animations.
    @IBOutlet weak var topBarView: UIView!
    
    /// 'Content' view including all view content below the custom navigation bar. Accessible from outside for use in animations.
    @IBOutlet weak var contentView: UIView!
    
    /// List of homes from the local realm database
    private var homeResults: Results<Home>? = nil
    
    /// Items to display; these roughly map to homeResults
    private var items = [HomeStoryItem]()
    
    /// Cell instance for calculating sizes
    private let sizingCell = HomeCell.loadFromNib()
    
    /// Pull to refresh
    private var refreshControl: UIRefreshControl?
    
    // MARK: Private methods
    
    private func updateData() {
        do {
            homeResults = try dataManager.listHomes()
        } catch let error {
            log.error("Error fetching homes: \(error)")
            return
        }
        
        // Only keep capacity if normal reload user not logging out
        let keepCapacity = homeResults?.count > 0
        items.removeAll(keepCapacity: keepCapacity)
        
        items.append(HomeStoryItem(home: dataManager.findMyHome(), isMyHomeCell: true))
        
        for home in homeResults! {
            items.append(HomeStoryItem(home: home))
        }
        
        log.debug("Now we have \(homeResults?.count) homes.")
        collectionView.reloadData()
    }
    
    // MARK: Public methods
    
    /// Finds the cell representing a home in the collection view, or nil if such home is not currently visible
    func cellForHome(home: Home) -> HomeCell? {
        for cell in collectionView.visibleCells() {
            if let homeCell = cell as? HomeCell where homeCell.home == home {
                return homeCell
            }
        }
        
        return nil
    }
    
    // MARK: IBAction handlers
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // No action; could we remove this?
    }
    
    @IBAction func profileButtonPressed(sender: UIButton) {
        if appstate.accessToken != nil {
            self.performSegueWithIdentifier(segueIdHomesToProfile, sender: self)
        } else {
            AuthenticationService.sharedInstance().logoutUser()
            showLoginRequested()
        }
    }
    
    // MARK: Notification handlers
    
    func homesUpdated() {
        updateData()
    }
    
    func userLoggedIn() {
        updateData()
        
        remoteService.fetchHomes() { response in
            if let message = localizedErrorMessage(response) {
                Toast.show(message: message)
            }
        }
    }

    func showLoginRequested() {
        let loginController = self.storyboard!.instantiateViewControllerWithIdentifier("LoginViewController")
        view.addSubview(loginController.view)
        addChildViewController(loginController)
    }
    
    // MARK: From UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HomeCell", forIndexPath: indexPath) as! HomeCell
        let item = items[indexPath.row]
        cell.isMyHomeCell = item.isMyHomeCell
        cell.home = item.home
        
        cell.cellTappedCallback = { [weak self] in
            if let strongSelf = self {
                if cell.isMyHomeCell && ((cell.home == nil) || !authService.isUserLoggedIn()) {
                    strongSelf.showLoginRequested()
                } else {
                    strongSelf.performSegueWithIdentifier(strongSelf.segueIdHomesToHomeStory, sender: cell)
                }
            }
        }
        
        // Set left and right margin to make grid look better
        if cell.frame.x == 0.0 {
            cell.rightMargin.constant = 3 / 2
            cell.leftMargin.constant = 3
        } else {
            cell.leftMargin.constant = 3 / 2
            cell.rightMargin.constant = 3
        }
        
        return cell
    }
    
    // MARK: From UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
    }

    // MARK: From HomeStoryLayoutDelegate
    
    func collectionView(collectionView: UICollectionView, heightForItemAtIndexPath indexPath: NSIndexPath, cellWidth: CGFloat) -> CGFloat {
        let item = items[indexPath.row]
        let home = item.home
        
        sizingCell.home = home
        sizingCell.bounds.size.width = cellWidth
        sizingCell.bounds.size.height = 9999
        
        sizingCell.setNeedsLayout()
        sizingCell.layoutIfNeeded()
        
        let fittingSize = sizingCell.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        
        return fittingSize.height
    }
    
    func pullRefresh() {
        remoteService.fetchHomes() { [weak self] response in
            self?.refreshControl?.endRefreshing()
            if let message = localizedErrorMessage(response) {
                Toast.show(message: message)
            } else {
                // animate after a bit of delay to hiden pull to refresh with animation
                runOnMainThreadAfter(delay: 0.4, task: {
                    self?.updateData()
                })
            }
        }
    }
    
    // MARK: From UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdHomesToHomeStory {
            if let cell = sender as? HomeCell,
                homeStorySegue = segue as? ShowHomeStorySegue,
                homeStoryViewController = segue.destinationViewController as? HomeStoryViewController {
                    homeStoryViewController.storyObject = cell.home
                    let bottomContainerSize = cell.bottomContainerView.frame.size
                    appstate.homeCellBottomContainerAspectRatio = bottomContainerSize.height / bottomContainerSize.width
                    appstate.mostRecentlyOpenedHome = cell.home
                    homeStorySegue.sourceCell = cell
                    homeStoryViewController.allowEditMode = cell.isMyHomeCell
            }
        }
    }
    
    // MARK: Lifecycle etc.
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        topBarView.userInteractionEnabled = true
        topBarView.transform = CGAffineTransformIdentity
        
        // Reload last selected cell since it may have been changed
        if appstate.accessToken != nil {
            for cell in collectionView.visibleCells() {
                let homeCell = cell as! HomeCell
                if homeCell.home == appstate.mostRecentlyOpenedHome {
                    if let indexPath = collectionView.indexPathForCell(cell) {
                        collectionView.reloadItemsAtIndexPaths([indexPath])
                    }
                }
            }
        }
    }
    
    deinit {
        log.debug("Homes view deallocated")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showLoginRequested), name: userLogoutNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(homesUpdated), name: homesUpdatedNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(userLoggedIn), name: loginSuccessNotification, object: nil);
        
        navigationController?.navigationBarHidden = true
        collectionView.registerNib(UINib(nibName: "HomeCell", bundle: nil), forCellWithReuseIdentifier: "HomeCell")
        
        if !authService.isUserLoggedIn() {
            self.showLoginRequested()
        }
        
        updateData()
        remoteService.fetchHomes() { response in
            if let message = localizedErrorMessage(response) {
                Toast.show(message: message)
            }
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullRefresh), forControlEvents: UIControlEvents.ValueChanged)
        self.collectionView.addSubview(refreshControl)
        self.refreshControl = refreshControl
        self.collectionView.alwaysBounceVertical = true
    }
}
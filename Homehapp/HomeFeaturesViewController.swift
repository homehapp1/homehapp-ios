//
//  HomeFeaturesViewController.swift
//  Homehapp
//
//  Created by Lari Tuominen on 7.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class HomeFeaturesViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet private weak var tableView: UITableView!
    
    var homeFeatures: [String] = []
    
    // TODO store these somewhere else than here... on server side with separate API, GET /features
    private var generalFeatures: [String] = ["Balcony", "Garden", "Central heating", "Electric heating", "Gas heating", "Garage", "Parking", "Swimming pool", "Air Conditioning", "Fireplace", "Mansion height ceilings"]
    private var serviceFeatures: [String] = ["Reception", "Porter", "Gym", "Laundry"]
    private var applianceFeatures: [String] = ["Washing machine", "Fridge", "Drier"]
    
    // MARK: IBActions
    
    @IBAction func backButtonPressed(sender: UIButton) {
        dataManager.performUpdates({
            appstate.mostRecentlyOpenedHome!.setFeatures(homeFeatures)
        })
        remoteService.updateMyHomeOnServer()
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: UITableView datasource and delegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return generalFeatures.count
        case 1:
            return serviceFeatures.count
        case 2:
            return applianceFeatures.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HomeFeatureSelectionCell", forIndexPath: indexPath) as! HomeFeatureSelectionCell
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let featureCell = cell as? HomeFeatureSelectionCell {
            var feature = ""
            switch indexPath.section {
            case 0:
                feature = generalFeatures[indexPath.row]
            case 1:
                feature = serviceFeatures[indexPath.row]
            case 2:
                feature = applianceFeatures[indexPath.row]
            default:
                feature = generalFeatures[indexPath.row]
            }
            featureCell.featureLabel.text = feature
            featureCell.tickImageView.hidden = !homeFeatures.contains(feature)
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier("HomeFeatureHeaderCell") as! HomeFeatureHeaderCell
        
        switch section {
        case 0:
            headerCell.headerLabel.text = NSLocalizedString("homefeatures:general", comment: "")
        case 1:
            headerCell.headerLabel.text = NSLocalizedString("homefeatures:services", comment: "")
        case 2:
            headerCell.headerLabel.text = NSLocalizedString("homefeatures:appliances", comment: "")
        default:
            headerCell.headerLabel.text = NSLocalizedString("homefeatures:general", comment: "")
        }
        headerCell.backgroundColor = UIColor.clearColor()
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 54.0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? HomeFeatureSelectionCell {
            cell.tickImageView.hidden = !cell.tickImageView.hidden
            if cell.tickImageView.hidden {
                homeFeatures = homeFeatures.filter{$0 != cell.featureLabel.text}
            } else {
                homeFeatures.append(cell.featureLabel.text!)
            }
        }
    }
    
    // MARK: Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "HomeFeatureSelectionCell", bundle: nil), forCellReuseIdentifier: "HomeFeatureSelectionCell")
        tableView.registerNib(UINib(nibName: "HomeFeatureHeaderCell", bundle: nil), forCellReuseIdentifier: "HomeFeatureHeaderCell")
        
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor.clearColor()
        homeFeatures = appstate.mostRecentlyOpenedHome!.getFeatures() as! [String]
    }
    
}

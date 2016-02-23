//
//  HomeFeaturesView.swift
//  Homehapp
//
//  Created by Lari Tuominen on 6.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class HomeFeaturesView: UIView, EditableHomeInfoView, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet private weak var editHomeFeaturesButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    @IBOutlet private weak var containerViewHeight: NSLayoutConstraint!
    
    private let reuseIdentifier = "HomeFeatureCell"
    private let cellHeight: CGFloat = 80
    
    var editFeaturesCallback: (Void -> Void)?
    
    var home: Home? = nil {
        didSet {
            //Divide features amount by 4 to get how many rows collectionView has
            let featuresAmount = home?.getFeatures().count ?? 0
            
            // 210 is eveything else on the cell but collectionView. TODO Get it programmatically!
            containerViewHeight.constant = ceil(CGFloat(featuresAmount) / 4) * cellHeight + 210
            
            collectionView.reloadData()
        }
    }
    
    // MARK: IBActions
    
    @IBAction func editFeaturesButtonPressed(sender: UIButton) {
        editFeaturesCallback?()
    }
    
    // MARK: UICollectionView datasource and delegate
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let featuresAmount = home?.getFeatures().count ?? 0
        return featuresAmount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let featureCell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? HomeFeatureCell
        featureCell!.feature = home?.getFeatures()[indexPath.row] as? String
        return featureCell!
    }
        
    // MARK: Lifecycle
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HomeFeaturesView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! HomeFeaturesView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.registerNib(UINib(nibName: "HomeFeatureCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    func setEditMode(editMode: Bool, animated: Bool) {
        editHomeFeaturesButton.hidden = !editMode
    }
    
}

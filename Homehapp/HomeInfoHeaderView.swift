//
//  HomeInfoHeaderView.swift
//  Homehapp
//
//  Created by Lari Tuominen on 31.1.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class HomeInfoHeaderView: UIView, EditableHomeInfoView {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let home = appstate.mostRecentlyOpenedHome!
        titleLabel.text = home.title.uppercaseString
        if home.addressStreet.length > 0 {
            if home.addressCity.length > 0 {
                if home.addressZipcode.length > 0 {
                    addressLabel.text = "\(home.addressStreet.length), \(home.addressCity), \(home.addressZipcode)"
                }
            } else {
                addressLabel.text = home.addressStreet
            }
        }
        
        if home.price > 0 && home.currency?.length > 0 {
            priceLabel.text = "\(home.price) \(home.currency!)"
        }
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HomeInfoHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UIView
    }
    
    func setEditMode(editMode: Bool, animated: Bool) {
    
    }

}

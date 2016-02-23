//
//  HomeFeatureCell.swift
//  Homehapp
//
//  Created by Lari Tuominen on 14.2.2016.
//  Copyright © 2016 Homehapp. All rights reserved.
//

import UIKit

class HomeFeatureCell: UICollectionViewCell {

    @IBOutlet private weak var featureLabel: UILabel!
    @IBOutlet private weak var featureImageView: UIImageView!

    var feature: String? = nil {
        didSet {
            if let feature = feature {
                featureLabel.text = feature
                featureImageView.image = imageForFeature(feature)
            }
        }
    }
    
    // MARK: Private methods
    
    private func imageForFeature(feature: String) -> UIImage! {
        switch feature.lowercaseString {
        case "balcony":
                return UIImage(named:"feature_balcony_active")
        case "garden":
                return UIImage(named:"feature_garden_active")
        case "central heating":
                return UIImage(named:"feature_central_heating_active")
        case "electric heating":
            return UIImage(named:"feature_electric_heating_active")
        case "gas heating":
            return UIImage(named:"feature_gas_heating_active")
        case "garage":
            return UIImage(named:"feature_garage_active")
        case "parking":
            return UIImage(named:"feature_parking_active")
        case "swimming pool":
            return UIImage(named:"feature_pool_active")
        case "air conditioning":
            return UIImage(named:"feature_ac_active")
        case "fireplace":
            return UIImage(named:"feature_fireplace_active")
        case "mansion height ceilings":
            return UIImage(named:"feature_high_ceiling_active")
        case "reception":
            return UIImage(named:"feature_reception_active")
        case "porter":
            return UIImage(named:"feature_porter_active")
        case "Gym":
            return UIImage(named:"feature_gym_active")
        case "laundry":
            return UIImage(named:"feature_laundry_active")
        case "washing machine":
            return UIImage(named:"feature_washing_machine_active")
        case "fridge":
            return UIImage(named:"feature_fridge_active")
        case "drier":
            return UIImage(named:"feature_drier_active")
        default:
            return UIImage(named:"feature_default_active")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
}

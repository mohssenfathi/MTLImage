//
//  SettingsCell.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 3/31/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

protocol SettingsCellDelegate {
    func settingsCellSliderValueChanged(sender: SettingsCell, value: Float)
}

class SettingsCell: UITableViewCell {

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    var delegate: SettingsCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func sliderValueChanged(sender: UISlider) {
        delegate?.settingsCellSliderValueChanged(self, value: sender.value)
    }
}

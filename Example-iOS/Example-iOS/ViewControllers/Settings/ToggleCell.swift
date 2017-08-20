//
//  ToggleCell.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 9/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

protocol ToggleCellDelegate {
    func toggleValueChanged(sender: ToggleCell, isOn: Bool)
}

class ToggleCell: UITableViewCell {

    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    var delegate: ToggleCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func switchToggled(_ sender: UISwitch) {
        valueLabel.text = sender.isOn ? "On" : "Off"
        delegate?.toggleValueChanged(sender: self, isOn: sender.isOn)
    }
}

//
//  PickerCell.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/14/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

protocol PickerCellDelegate {
    func pickerCellDidSelectItem(sender: PickerCell, index: Int)
}

class PickerCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var picker: UIPickerView!
    @IBOutlet var titleLabel: UILabel!
    var selectionItems = [Int : String]()
    var delegate: PickerCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    
//    MARK: - UIPickerView
//    MARK: DataSource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectionItems.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return selectionItems[row]
    }
    
//    MARK: Delegate
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.pickerCellDidSelectItem(self, index: row)
    }
}

//
//  SettingsViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 3/31/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MTLImage

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
SettingsCellDelegate, PickerCellDelegate, ToggleCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    var filter: Filter!
    var touchProperty: Property?
    var mainViewController: MainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = filter.title
        tableView.estimatedRowHeight = 80
        
        mainViewController = self.navigationController?.parent as! MainViewController
    
        for property: Property in filter.properties {
            if property.propertyType == .point {
                touchProperty = property
                break;
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.isHidden  = (filter.properties.count == 0)
        emptyLabel.isHidden = (filter.properties.count != 0)
    }
    
    
    func handleTouchAtLocation(_ location: CGPoint) {
        
        if filter is Smudge { return } // Temp
        
        if touchProperty != nil {
            let viewSize = mainViewController.mtlView.frame.size
            let point = CGPoint(x: location.x / viewSize.width, y: location.y / viewSize.height)
            filter.setValue(NSValue(cgPoint: point), forKey: touchProperty!.key)
        }
    }
    
    func handlePan(_ sender: UIPanGestureRecognizer) {
        
        let translation = sender.translation(in: sender.view)
        let location    = sender.location(in: sender.view)
//        let velocity    = sender.velocityInView(sender.view)
        
        if let smudgeFilter = filter as? Smudge {
            smudgeFilter.location = location
            smudgeFilter.direction = translation
//            smudgeFilter.force = Float(max(velocity.x, velocity.y))
        }
        
    }
    
    //    MARK: - UITableView
    //    MARK: DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filter.properties.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == filter.properties.count { return 80.0 }
        if cellIdentifier(filter.properties[indexPath.row].propertyType) == "pickerCell" {
            return 200.0
        }
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier: String!
        if indexPath.row == filter.properties.count {
            identifier = "resetCell"
        } else {
            identifier = cellIdentifier(filter.properties[indexPath.row].propertyType)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        return cell
    }
    
    func cellIdentifier(_ propertyType: Property.PropertyType) -> String {
        if      propertyType == .selection { return "pickerCell" }
        else if propertyType == .image     { return "imageCell"  }
        else if propertyType == .bool      { return "toggleCell" }
        return "settingsCell"
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if cell.reuseIdentifier == "settingsCell" {
            let settingsCell: SettingsCell = cell as! SettingsCell
            let property: Property = filter.properties[indexPath.row]
            
            settingsCell.delegate = self
            settingsCell.titleLabel.text = property.title
            
            if property.propertyType == .value {
                let value = filter.value(forKey: property.key!) as! Float
                
                settingsCell.spectrum = false
                settingsCell.valueLabel.text = String(format: "%.2f", value)
                settingsCell.slider.value = value
            }
            else if property.propertyType == .color {
                settingsCell.spectrum = true
                settingsCell.valueLabel.text = "-"
            }
            else if property.propertyType == .point {
                settingsCell.message = "Touch preview image to adjust."
            }
        }
        else if cell.reuseIdentifier == "toggleCell" {
            
            let toggleCell: ToggleCell = cell as! ToggleCell
            toggleCell.titleLabel.text = filter.properties[indexPath.row].title
            toggleCell.delegate = self
            
            if let key = filter.properties[indexPath.row].key {
                if let isOn = filter.value(forKey: key) as? Bool {
                    toggleCell.toggleSwitch.isOn = isOn
                }
            }
            
        }
        else if cell.reuseIdentifier == "pickerCell" {
            let pickerCell: PickerCell = cell as! PickerCell
            pickerCell.titleLabel.text = filter.properties[indexPath.row].title
            pickerCell.selectionItems  = filter.properties[indexPath.row].selectionItems!
            pickerCell.delegate = self
        }
    }
    
//    MARK: Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        
        if cell?.reuseIdentifier == "resetCell" {
            filter.reset()
        }
        else if cell?.reuseIdentifier == "imageCell" {
            let navigationController = parent as! UINavigationController
//            let mainViewController = navigationController?.parentViewController as? MainViewController
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            navigationController.present(imagePicker, animated: true, completion: nil)
            
            currentImageHandler = { image in
                let property = self.filter.properties[indexPath.row]
                self.filter.setValue(image, forKey: property.key)
            }
        }
    }
    
    var currentImageHandler: ((_ image: UIImage) -> ())?
    
    // MARK: SettingsCell Delegate
    
    func settingsCellSliderValueChanged(_ sender: SettingsCell, value: Float) {
        let indexPath = tableView.indexPath(for: sender)

        let property: Property = filter.properties[(indexPath?.row)!]
        
        if property.propertyType == .value {
            sender.valueLabel.text = String(format: "%.2f", value)
            filter.setValue(value, forKey: property.key)
        }
        else if property.propertyType == .color {
            sender.valueLabel.text = "-"
            filter.setValue(sender.currentColor(), forKey: property.key)
        }

    }
    
    // MARK: PickerCell Delegate
    
    func pickerCellDidSelectItem(_ sender: PickerCell, index: Int) {
        let indexPath = tableView.indexPath(for: sender)
        let property: Property = filter.properties[(indexPath?.row)!]
        filter.setValue(index, forKey: property.key)
    }
    
    // MARK: ToggleCell Delegate
    
    func toggleValueChanged(sender: ToggleCell, isOn: Bool) {
        let indexPath = tableView.indexPath(for: sender)
        let property: Property = filter.properties[(indexPath?.row)!]
        filter.setValue(isOn, forKey: property.key)
    }
    
//    MARK: ImagePickerController Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        for property in filter.properties {
            if property.propertyType == .image {
                if let image: UIImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    currentImageHandler?(image)
                    dismiss(animated: true, completion: nil)
                    return
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

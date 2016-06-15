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
SettingsCellDelegate, PickerCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    var filter: MTLFilter!
    var touchProperty: MTLProperty?
    var mainViewController: MainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = filter.title
        tableView.estimatedRowHeight = 80
        
        mainViewController = self.navigationController?.parent as! MainViewController
    
        for property: MTLProperty in filter.properties {
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
    
    func handlePan(_ sender: UIPanGestureRecognizer) {
        
        let translation = sender.translation(in: sender.view)
        let location    = sender.location(in: sender.view)
//        let velocity    = sender.velocityInView(sender.view)
        
        if let smudgeFilter = filter as? MTLSmudgeFilter {
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
    
    func handleTouchAtLocation(_ location: CGPoint) {
        
        if filter is MTLSmudgeFilter { return } // Temp
        
        if touchProperty != nil {
            filter.setValue(NSValue(cgPoint: location), forKey: touchProperty!.key)
        }
    }
    
    func cellIdentifier(_ propertyType: MTLPropertyType) -> String {
        if propertyType == .selection { return "pickerCell" }
        else if propertyType == .image { return "imageCell" }
//         Add switchCell later...
        return "settingsCell"
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if cell.reuseIdentifier == "settingsCell" {
            let settingsCell: SettingsCell = cell as! SettingsCell
            let property: MTLProperty = filter.properties[indexPath.row]
            
            settingsCell.delegate = self
            settingsCell.titleLabel.text = property.title
            
            if property.propertyType == .value {
                let value: Float = filter.value(forKey: property.key) as! Float
                
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
        }
    }
    
    // MARK: SettingsCell Delegate
    
    func settingsCellSliderValueChanged(_ sender: SettingsCell, value: Float) {
        let indexPath = tableView.indexPath(for: sender)

        let property: MTLProperty = filter.properties[(indexPath?.row)!]
        
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
        let property: MTLProperty = filter.properties[(indexPath?.row)!]
        filter.setValue(index, forKey: property.key)
    }
    
    
//    MARK: ImagePickerController Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        for property in filter.properties {
            if property.propertyType == .image {
                let image = info[UIImagePickerControllerOriginalImage]
                filter.setValue(image, forKey: property.key)
                dismiss(animated: true, completion: nil)
                return
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

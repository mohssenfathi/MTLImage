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
        
        mainViewController = self.navigationController?.parentViewController as! MainViewController
    
        for property: MTLProperty in filter.properties {
            if property.propertyType == .Point {
                touchProperty = property
                break;
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.hidden  = (filter.properties.count == 0)
        emptyLabel.hidden = (filter.properties.count != 0)
    }
    
    func handlePan(sender: UIPanGestureRecognizer) {
        
        let translation = sender.translationInView(sender.view)
        let location    = sender.locationInView(sender.view)
//        let velocity    = sender.velocityInView(sender.view)
        
        if let smudgeFilter = filter as? MTLSmudgeFilter {
            smudgeFilter.location = location
            smudgeFilter.direction = translation
//            smudgeFilter.force = Float(max(velocity.x, velocity.y))
        }
        
    }
    
    //    MARK: - UITableView
    //    MARK: DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filter.properties.count + 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == filter.properties.count { return 80.0 }
        if cellIdentifier(filter.properties[indexPath.row].propertyType) == "pickerCell" {
            return 200.0
        }
        return 80.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var identifier: String!
        if indexPath.row == filter.properties.count {
            identifier = "resetCell"
        } else {
            identifier = cellIdentifier(filter.properties[indexPath.row].propertyType)
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
        
        return cell
    }
    
    func handleTouchAtLocation(location: CGPoint) {
        
        if filter is MTLSmudgeFilter { return } // Temp
        
        if touchProperty != nil {
            filter.setValue(NSValue(CGPoint: location), forKey: touchProperty!.key)
        }
    }
    
    func cellIdentifier(propertyType: MTLPropertyType) -> String {
        if propertyType == .Selection { return "pickerCell" }
        else if propertyType == .Image { return "imageCell" }
//         Add switchCell later...
        return "settingsCell"
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if cell.reuseIdentifier == "settingsCell" {
            let settingsCell: SettingsCell = cell as! SettingsCell
            let property: MTLProperty = filter.properties[indexPath.row]
            
            settingsCell.delegate = self
            settingsCell.titleLabel.text = property.title
            
            if property.propertyType == .Value {
                let value: Float = filter.valueForKey(property.key) as! Float
                
                settingsCell.spectrum = false
                settingsCell.valueLabel.text = String(format: "%.2f", value)
                settingsCell.slider.value = value
            }
            else if property.propertyType == .Color {
                settingsCell.spectrum = true
                settingsCell.valueLabel.text = "-"
            }
            else if property.propertyType == .Point {
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        if cell?.reuseIdentifier == "resetCell" {
            filter.reset()
        }
        else if cell?.reuseIdentifier == "imageCell" {
            let navigationController = parentViewController as! UINavigationController
//            let mainViewController = navigationController?.parentViewController as? MainViewController
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            navigationController.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: SettingsCell Delegate
    
    func settingsCellSliderValueChanged(sender: SettingsCell, value: Float) {
        let indexPath = tableView.indexPathForCell(sender)

        let property: MTLProperty = filter.properties[(indexPath?.row)!]
        
        if property.propertyType == .Value {
            sender.valueLabel.text = String(format: "%.2f", value)
            filter.setValue(value, forKey: property.key)
        }
        else if property.propertyType == .Color {
            sender.valueLabel.text = "-"
            filter.setValue(sender.currentColor(), forKey: property.key)
        }

    }
    
    // MARK: PickerCell Delegate
    
    func pickerCellDidSelectItem(sender: PickerCell, index: Int) {
        let indexPath = tableView.indexPathForCell(sender)
        let property: MTLProperty = filter.properties[(indexPath?.row)!]
        filter.setValue(index, forKey: property.key)
    }
    
    
//    MARK: ImagePickerController Delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        for property in filter.properties {
            if property.propertyType == .Image {
                filter.setValue(image, forKey: property.key)
                dismissViewControllerAnimated(true, completion: nil)
                return
            }
        }
        dismissViewControllerAnimated(true, completion: nil)
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

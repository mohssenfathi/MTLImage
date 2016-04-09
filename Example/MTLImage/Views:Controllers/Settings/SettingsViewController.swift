//
//  SettingsViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 3/31/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MTLImage

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SettingsCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    var filter: MTLFilter!
    var touchProperty: MTLProperty?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = filter.title
        tableView.rowHeight = 80
        
        for mtlProperty: MTLProperty in filter.properties {
            if let _ = mtlProperty.type as? CGPoint {
                touchProperty = mtlProperty
                break;
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.hidden  = (filter.properties.count == 0)
        emptyLabel.hidden = (filter.properties.count != 0)
    }
    
    //    MARK: - UITableView
    //    MARK: DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filter.properties.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: SettingsCell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath) as! SettingsCell
        
        return cell
    }
    
    func handleTouchAtLocation(location: CGPoint) {
        if touchProperty != nil {
            filter.setValue(NSValue(CGPoint: location), forKey: touchProperty!.key)
        }
    }
    
    
    //    MARK: SettingsCell Delegate
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let settingsCell: SettingsCell = cell as! SettingsCell
        let property: MTLProperty = filter.properties[indexPath.row]
        
        settingsCell.delegate = self
        settingsCell.titleLabel.text = property.title
        
        if let _ = property.type as? Float {
            let value: Float = filter.valueForKey(property.key) as! Float
            
            settingsCell.spectrum = false
            settingsCell.valueLabel.text = String(format: "%.2f", value)
            settingsCell.slider.value = value
        }
        else if let _ = property.type as? UIColor {
            settingsCell.spectrum = true
            settingsCell.valueLabel.text = "-"
        }
        else if let _ = property.type as? CGPoint {
            settingsCell.message = "Touch preview image to adjust."
        }
    }
    
    func settingsCellSliderValueChanged(sender: SettingsCell, value: Float) {
        let indexPath = tableView.indexPathForCell(sender)

        let property: MTLProperty = filter.properties[(indexPath?.row)!]
        
        if let _ = property.type as? Float {
            sender.valueLabel.text = String(format: "%.2f", value)
            filter.setValue(value, forKey: property.key)
        }
        else if let _ = property.type as? UIColor {
            sender.valueLabel.text = "-"
            filter.setValue(sender.currentColor(), forKey: property.key)
        }

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

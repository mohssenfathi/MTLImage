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
    
    var filter: MTLFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = filter.title
        tableView.rowHeight = 80
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
        
        let property: MTLProperty = filter.properties[indexPath.row]
        let value: Float = filter.valueForKey(property.key) as! Float
        
        cell.delegate = self
        cell.titleLabel.text = property.title
        cell.valueLabel.text = String(format: "%.2f", value)
        cell.slider.value = value
        
        return cell
    }
    
    
    //    MARK: SettingsCell Delegate
    
    func settingsCellSliderValueChanged(sender: SettingsCell, value: Float) {
        let indexPath = tableView.indexPathForCell(sender)
        
        
        let property: MTLProperty = filter.properties[(indexPath?.row)!]
        
        
        sender.valueLabel.text = String(format: "%.2f", value)
        filter.setValue(value, forKey: property.key)
        
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

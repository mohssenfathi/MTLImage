//
//  FilterGroupViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/9/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MTLImage

class FilterGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddFilterViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    var filterGroup: MTLFilterGroup!
    var selectedFilter: MTLFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Filter Group"
        tableView.reloadData()
        tableView.setEditing(true, animated: false)
    }
    
    
    //    MARK: - UITableView
    //    MARK: DataSource
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == filterGroup.filters.count { return 80.0 }
        return 70.0
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterGroup.filters.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        if indexPath.row == filterGroup.filters.count {
            return tableView.dequeueReusableCellWithIdentifier("addCell", forIndexPath: indexPath)
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = filterGroup.filters[indexPath.row].title
        return cell
    }
    
    
    //    MARK: Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        if cell?.reuseIdentifier == "addCell" {
            performSegueWithIdentifier("addFilter", sender: self)
        }
        else {
            selectedFilter = filterGroup.filters[indexPath.row]
            performSegueWithIdentifier("settings", sender: self)
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.row == filterGroup.filters.count { return false }
        return true
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if indexPath.row == filterGroup.filters.count { return .None }
        return .Delete
    }
    
//    MARK: - AddFilterViewController Delegate
    
    func addFilterViewControllerDidSelectFilter(sender: AddFilterViewController, filter: MTLFilter) {
        filterGroup += filter
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            filterGroup.remove(filterGroup.filters[indexPath.row])
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        if indexPath.row == filterGroup.filters.count { return nil }
        
        let action = UITableViewRowAction(style: .Default, title: "Delete", handler: { (action, indexPath) in
            self.filterGroup.remove(self.filterGroup.filters[indexPath.row])
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        })
        
        return [action]
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        filterGroup.move(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.row == filterGroup.filters.count { return false }
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "settings" {
            let settingsViewController = segue.destinationViewController as! SettingsViewController
            settingsViewController.filter = selectedFilter
        }
        else if segue.identifier == "addFilter" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let addFilterViewController = navigationController.viewControllers.first as! AddFilterViewController
            addFilterViewController.delegate = self
        }
    }

}

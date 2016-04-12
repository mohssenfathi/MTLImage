//
//  FiltersViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MTLImage

protocol FiltersViewControllerDelegate {
    func filtersViewControllerDidSelectFilter(sender: FiltersViewController, filter: MTLFilter)
    func filtersViewControllerDidSelectFilterGroup(sender: FiltersViewController, filterGroup: MTLFilterGroup)
    func filtersViewControllerBackButtonPressed(sender: FiltersViewController)
}

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var settingsViewController: SettingsViewController?
    var selectedFilter: MTLFilter!
    var delegate: FiltersViewControllerDelegate?
    var filterNames = Array(MTLImage.filters.keys).sort()
    var savedFilterGroups: [MTLFilterGroup]!
    var filterGroup: MTLFilterGroup!
    var newFilterSeleced: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        savedFilterGroups = MTLImage.savedFilterGroups()
        editButton.enabled = savedFilterGroups.count > 0
        tableView.reloadData()
    }
    
    func handleTouchAtLocation(location: CGPoint) {
        settingsViewController?.handleTouchAtLocation(location)
    }
    
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        let edit = !tableView.editing
        sender.title = edit ? "Done" : "Edit"
        tableView.setEditing(edit, animated: true)
    }
    
    
//    MARK: - UINavigationController Delegate

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController == navigationController.viewControllers.first {
            delegate?.filtersViewControllerBackButtonPressed(self)
        }
    }
    
//    MARK: - UITableView
//    MARK: DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return savedFilterGroups.count + 1 }
        return filterNames.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Saved Filters" : "Single Filters"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        
        if indexPath.section == 0 {
            if indexPath.row == savedFilterGroups.count {
                cell = tableView.dequeueReusableCellWithIdentifier("addCell", forIndexPath: indexPath)
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
                cell.textLabel?.text = savedFilterGroups[indexPath.row].title
            }
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            cell.textLabel?.text = filterNames[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 && indexPath.row != savedFilterGroups.count {
            return true
        }
        return false
    }
    
    
    //    MARK: Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == savedFilterGroups.count {
                filterGroup = MTLFilterGroup()
                newFilterSeleced = true
            } else {
                filterGroup = savedFilterGroups[indexPath.row]
                newFilterSeleced = false
            }
            
            delegate?.filtersViewControllerDidSelectFilterGroup(self, filterGroup: filterGroup)
            performSegueWithIdentifier("filterGroup", sender: self)
        }
        else {
            let title = filterNames[indexPath.row]
            selectedFilter = MTLImage.filters[title]
            delegate?.filtersViewControllerDidSelectFilter(self, filter: selectedFilter)
            performSegueWithIdentifier("settings", sender: self)
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let filterGroup = savedFilterGroups[indexPath.row]
            MTLImage.remove(filterGroup, completion: { (success) in
                if success == true {
                    self.savedFilterGroups.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            })
        }
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = self.savedFilterGroups[indexPath.row].title
        }
        
        let doneAction = UIAlertAction(title: "Done", style: .Default) { (action) in
            let textField = alert.textFields?.first!
            if textField!.text == nil || textField!.text == "" { return }
            let filterGroup = self.savedFilterGroups[indexPath.row]
            filterGroup.title = textField!.text!
            self.tableView.reloadData()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "settings" {
            settingsViewController = segue.destinationViewController as? SettingsViewController
            settingsViewController?.filter = selectedFilter
        }
        else if segue.identifier == "filterGroup" {
            let filterGroupViewController = segue.destinationViewController as! FilterGroupViewController
            filterGroupViewController.filterGroup = filterGroup
            filterGroupViewController.isNewFilter = newFilterSeleced
        }
    }

}

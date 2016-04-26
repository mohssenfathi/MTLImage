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
    var settingsViewController: SettingsViewController?
    var filterGroup: MTLFilterGroup!
    var selectedFilter: MTLFilter!
    var saveButton: UIBarButtonItem!
    var isNewFilter: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        tableView.setEditing(true, animated: false)
    }

    func saveButtonPressed(button: UIBarButtonItem) {
        if isNewFilter {
            showRenameAlert({ 
                MTLImage.save(self.filterGroup, completion: { (success) in
                    if success == true {
                        self.saveButton.enabled = false
                    }
                })
            })
        } else {
            MTLImage.save(self.filterGroup, completion: { (success) in
                if success == true {
                    self.saveButton.enabled = false
                }
            })
        }
    }
    
    func handleTouchAtLocation(location: CGPoint) {
        settingsViewController?.handleTouchAtLocation(location)
    }
    
    func showRenameAlert(completion: (() -> ())?) {
        let alert = UIAlertController(title: "Name this filter group", message: nil, preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = self.filterGroup.title
        }
        
        let doneAction = UIAlertAction(title: "Done", style: .Default) { (action) in
            let textField = alert.textFields?.first!
            if textField!.text == nil || textField!.text == "" { return }
            self.filterGroup.title = textField!.text!
            self.navigationItem.title = textField?.text
            self.isNewFilter = false
            self.dismissViewControllerAnimated(true, completion: nil)
            completion?()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in
            MTLImage.save(self.filterGroup, completion: { (success) in
                self.dismissViewControllerAnimated(true, completion: nil)
                completion?()
            })
        }
        
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func setupView() {
        saveButton = UIBarButtonItem(title: "Save", style: .Done, target: self, action: "saveButtonPressed")
        saveButton.enabled = false
        navigationItem.rightBarButtonItem = saveButton
        
        navigationItem.title = filterGroup.title
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
        
        saveButton.enabled = true
        
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
    
    var histogramView: UIView?
    
    func addFilterViewControllerDidSelectFilter(sender: AddFilterViewController, filter: MTLFilter) {
    
        if histogramView == nil {
            if filter is MTLHistogramFilter {
                let histogram = filter as! MTLHistogramFilter
                if histogram.histogramView != nil {
                    histogramView = histogram.histogramView
                    let window = UIApplication.sharedApplication().keyWindow!
                    histogramView!.center = CGPointMake(view.frame.size.width/2, 200)
                    window.addSubview(histogramView!)
                }
            }
        }
        
        
        filterGroup += filter
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            filterGroup.remove(filterGroup.filters[indexPath.row])
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            saveButton.enabled = true
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
            settingsViewController = segue.destinationViewController as? SettingsViewController
            settingsViewController?.filter = selectedFilter
        }
        else if segue.identifier == "addFilter" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let addFilterViewController = navigationController.viewControllers.first as! AddFilterViewController
            addFilterViewController.delegate = self
        }
    }

}

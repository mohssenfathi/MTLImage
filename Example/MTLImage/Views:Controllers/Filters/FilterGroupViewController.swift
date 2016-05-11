//
//  FilterGroupViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/9/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MessageUI
import MTLImage

class FilterGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddFilterViewControllerDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    var settingsViewController: SettingsViewController?
    var filterGroup: MTLFilterGroup!
    var selectedFilter: MTLFilter!
    var actionButton: UIBarButtonItem!
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

    func actionButtonPressed(button: UIBarButtonItem) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let exportAction = UIAlertAction(title: "Export", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion:nil)
            self.export()
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion:nil)
            self.save()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alert.addAction(saveAction)
        alert.addAction(exportAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func save() {
        if isNewFilter {
            showRenameAlert({
                MTLImage.save(self.filterGroup, completion: { (success) in
                    let message = success ? "Saved" : "Couldn't Save"
                    let alertView = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
                    self.presentViewController(alertView, animated: true, completion: { 
                        sleep(UInt32(1.0))
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                })
            })
        } else {
            MTLImage.save(self.filterGroup, completion: { (success) in
                let message = success ? "Saved" : "Couldn't Save"
                let alertView = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
                self.presentViewController(alertView, animated: true, completion: {
                    sleep(UInt32(1.0))
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            })
        }
    }
    
    
    func export() {
    
        let exportBlock = {
            let data = MTLImage.archive(self.filterGroup)
            let composeViewController = MFMailComposeViewController()
            composeViewController.setSubject("MTLImage Export Document - " + self.filterGroup.title)
            composeViewController.mailComposeDelegate = self
            composeViewController.addAttachmentData(data!, mimeType: "application/octet-stream", fileName: self.filterGroup.title)
            self.presentViewController(composeViewController, animated: true, completion: nil)
        }
        
        if isNewFilter {
            showRenameAlert({
                exportBlock();
            })
        } else {
            exportBlock();
        }
    }
    
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true) {
            
            if result == MFMailComposeResultCancelled { return }
            
            let message = (result == MFMailComposeResultFailed) ? "Failed to send" : "Sent"
            let alertView = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
            
            self.presentViewController(alertView, animated: true, completion: {
                sleep(UInt32(1.0))
                self.dismissViewControllerAnimated(true, completion: nil)
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
        actionButton = UIBarButtonItem(title: "•••", style: .Done, target: self, action: #selector(FilterGroupViewController.actionButtonPressed(_:)))
        navigationItem.rightBarButtonItem = actionButton
        actionButton.enabled = filterGroup.filters.count > 0
    
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
        
        actionButton.enabled = true
        
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
        
        actionButton.enabled = true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            filterGroup.remove(filterGroup.filters[indexPath.row])
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            actionButton.enabled = filterGroup.filters.count > 0
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

//
//  FiltersViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MTLImage
import MessageUI

protocol FiltersViewControllerDelegate {
    func filtersViewControllerDidSelectFilter(_ sender: FiltersViewController, filter: MTLObject)
    func filtersViewControllerDidSelectFilterGroup(_ sender: FiltersViewController, filterGroup: MTLObject)
    func filtersViewControllerBackButtonPressed(_ sender: FiltersViewController)
}

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var settingsViewController: SettingsViewController?
    var filterGroupViewController: FilterGroupViewController?
    var selectedFilter: MTLObject!
    var delegate: FiltersViewControllerDelegate?
    var filterTypes: [MTLImage.FilterType] = MTLImage.FilterType.all
    var savedFilterGroups: [FilterGroup]!
    var filterGroup: FilterGroup!
    var newFilterSeleced: Bool!
    var mainViewController: MainViewController? {
        return settingsViewController?.mainViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        loadSavedFilters()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mainViewController?.resetFilterGroup()
        
        editButton.isEnabled = savedFilterGroups.count > 0
        tableView.reloadData()
    }
    
    func loadSavedFilters() {
        savedFilterGroups = MTLImage.savedFilterGroups()
        
//        let path = NSBundle.mainBundle().pathForResource("Retro", ofType: "")
//        let data = NSData(contentsOfFile: path!)
//        let filterGroup = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! FilterGroup
//        savedFilterGroups.append(filterGroup)
    }
    
    func handleTouchAtLocation(_ location: CGPoint) {
        settingsViewController?.handleTouchAtLocation(location)
        filterGroupViewController?.handleTouchAtLocation(location)
    }
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        let edit = !tableView.isEditing
        sender.title = edit ? "Done" : "Edit"
        tableView.setEditing(edit, animated: true)
    }
    
    @IBAction func exportAllButtonPressed(_ sender: UIBarButtonItem) {
        exportAll()
    }

    
    func exportAll() {
    
        guard MFMailComposeViewController.canSendMail() else {
            print("Cannot send mail")
            return
        }
        
        let composeViewController = MFMailComposeViewController()
        composeViewController.mailComposeDelegate = self
        composeViewController.setSubject("MTLImage Export Document - " + self.filterGroup.title)
        
        for filterGroup in savedFilterGroups {
            let data = MTLImage.archive(filterGroup)
            composeViewController.addAttachmentData(data!, mimeType: "application/octet-stream", fileName: filterGroup.title)
        }
        
        self.present(composeViewController, animated: true, completion: nil)
    }
    
    
//    MARK: - UINavigationController Delegate

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == navigationController.viewControllers.first {
//            delegate?.filtersViewControllerBackButtonPressed(self)
        }
    }
    
//    MARK: - UITableView
//    MARK: DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return savedFilterGroups.count + 1 }
        return filterTypes.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Saved Filters" : "Single Filters"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        
        if (indexPath as NSIndexPath).section == 0 {
            if indexPath.row == savedFilterGroups.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath)
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = savedFilterGroups[indexPath.row].title
            }
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = filterTypes[indexPath.row].title
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (indexPath as NSIndexPath).section == 0 && indexPath.row != savedFilterGroups.count {
            return true
        }
        return false
    }
    
    
    //    MARK: Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath as NSIndexPath).section == 0 {
            if indexPath.row == savedFilterGroups.count {
                filterGroup = FilterGroup()
                newFilterSeleced = true
            } else {
                filterGroup = savedFilterGroups[indexPath.row]
                filterGroup.needsUpdate = true
                newFilterSeleced = false
            }
            
            delegate?.filtersViewControllerDidSelectFilterGroup(self, filterGroup: filterGroup)
            performSegue(withIdentifier: "filterGroup", sender: self)
        }
        else {
            let object = filterTypes[indexPath.row].filter()
            
            if object is Filter {
                selectedFilter = object as! Filter
                delegate?.filtersViewControllerDidSelectFilter(self, filter: selectedFilter)
                self.performSegue(withIdentifier: "settings", sender: self)
            }
            else if object is FilterGroup {
                selectedFilter = object as! FilterGroup
                delegate?.filtersViewControllerDidSelectFilterGroup(self, filterGroup: selectedFilter)
                performSegue(withIdentifier: "filterGroup", sender: self)
            }
            else {
                selectedFilter = object
                delegate?.filtersViewControllerDidSelectFilter(self, filter: selectedFilter)
                performSegue(withIdentifier: "settings", sender: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let filterGroup = savedFilterGroups[indexPath.row]
            MTLImage.remove(filterGroup, completion: { (success) in
                if success == true {
                    self.savedFilterGroups.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = self.savedFilterGroups[indexPath.row].title
        })
        
        let doneAction = UIAlertAction(title: "Done", style: .default) { (action) in
            let textField = alert.textFields?.first!
            if textField!.text == nil || textField!.text == "" { return }
            let filterGroup = self.savedFilterGroups[indexPath.row]
            filterGroup.title = textField!.text!
            self.tableView.reloadData()
            self.dismiss(animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "settings" {
            settingsViewController = segue.destination as? SettingsViewController
            settingsViewController?.filter = selectedFilter
        }
        else if segue.identifier == "filterGroup" {
            filterGroupViewController = segue.destination as? FilterGroupViewController
            if selectedFilter is FilterGroup {
                filterGroupViewController?.filterGroup = selectedFilter as! FilterGroup
            } else {
                filterGroupViewController?.filterGroup = filterGroup
                filterGroupViewController?.isNewFilter = newFilterSeleced
            }
        }
    }

}


extension FiltersViewController: MFMailComposeViewControllerDelegate {
 
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            
            if result == MFMailComposeResult.cancelled { return }
            
            let message = (result == MFMailComposeResult.failed) ? "Failed to send" : "Sent"
            let alertView = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            
            self.present(alertView, animated: true, completion: {
                sleep(UInt32(1.0))
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
}

//
//  FilterGroupViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/9/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import CloudKit
import MessageUI
import MTLImage

class FilterGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddFilterViewControllerDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    var settingsViewController: SettingsViewController?
    var filterGroup: FilterGroup!
    var selectedFilter: MTLObject!
    var actionButton: UIBarButtonItem!
    var isNewFilter: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        tableView.setEditing(true, animated: false)
    }

    @objc func actionButtonPressed(_ button: UIBarButtonItem) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let exportAction = UIAlertAction(title: "Export", style: .default) { (action) in
            self.dismiss(animated: true, completion:nil)
            self.export()
        }
        
        let uploadAction = UIAlertAction(title: "Upload", style: .default) { (action) in
            self.dismiss(animated: true, completion:nil)
            self.upload()
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
            self.dismiss(animated: true, completion:nil)
            self.save()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(saveAction)
        alert.addAction(uploadAction)
        alert.addAction(exportAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func upload() {
        
        let uploadBlock = { [weak self] in
        
            guard let filterGroup = self?.filterGroup else { return }
        
            let container = CKContainer(identifier: "iCloud.com.mohssenfathi.Lumen-iOS")
            
            MTLImage.upload(filterGroup, container: container, completion: { (record, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                
                let alertView = UIAlertController(title: nil, message: "Uploaded", preferredStyle: .alert)
                self?.present(alertView, animated: true, completion: {
                    sleep(UInt32(1.0))
                    self?.dismiss(animated: true, completion: nil)
                })
            })
        }
        
        
        showUploadAlert({ (name, category) in
            self.filterGroup.title = name
            self.filterGroup.category = category
            uploadBlock()
        })
    }
    
    func save() {
        
        let saveBlock = {
            MTLImage.save(self.filterGroup, completion: { (success) in
                let message = success ? "Saved" : "Couldn't Save"
                let alertView = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                self.present(alertView, animated: true, completion: {
                    sleep(UInt32(1.0))
                    self.dismiss(animated: true, completion: nil)
                })
            })
        }
        
        if isNewFilter {
            showRenameAlert({
                saveBlock()
            })
        } else {
            saveBlock()
        }
    }
    
    
    func export() {
    
        let exportBlock = {
            let data = MTLImage.archive(self.filterGroup)
            
            if !MFMailComposeViewController.canSendMail() {
                print("Cannot send mail")
                return
            }
            
            let composeViewController = MFMailComposeViewController()
            composeViewController.setSubject("MTLImage Export Document - " + self.filterGroup.title)
            composeViewController.mailComposeDelegate = self
            composeViewController.addAttachmentData(data!, mimeType: "application/octet-stream", fileName: self.filterGroup.title)
            self.present(composeViewController, animated: true, completion: nil)
        }
        
        if isNewFilter {
            showRenameAlert({
                exportBlock();
            })
        } else {
            exportBlock();
        }
    }
    
    
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
    
    func handleTouchAtLocation(_ location: CGPoint) {
        settingsViewController?.handleTouchAtLocation(location)
    }
    
    func showRenameAlert(_ completion: (() -> ())?) {
        let alert = UIAlertController(title: "Name this filter group", message: nil, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = self.filterGroup.title
        })
        
        let doneAction = UIAlertAction(title: "Done", style: .default) { (action) in
            let textField = alert.textFields?.first!
            if textField!.text == nil || textField!.text == "" { return }
            self.filterGroup.title = textField!.text!
            self.navigationItem.title = textField?.text
            self.isNewFilter = false
            self.dismiss(animated: true, completion: nil)
            completion?()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            MTLImage.save(self.filterGroup, completion: { (success) in
                self.dismiss(animated: true, completion: nil)
                completion?()
            })
        }
        
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func showUploadAlert(_ completion: ((_ name: String, _ category: String) -> ())?) {
        let alert = UIAlertController(title: "Name this filter group", message: nil, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = self.filterGroup.title
            if self.filterGroup.title != "" {
                textField.text = self.filterGroup.title
            }
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Category"
            if self.filterGroup.title != "" {
                textField.text = self.filterGroup.category
            }
        }
        
        let doneAction = UIAlertAction(title: "Done", style: .default) { (action) in
            let nameTextField = alert.textFields?.first!
            if nameTextField!.text == nil || nameTextField!.text == "" { return }
            
            let categoryTextField = alert.textFields?.last!
            if categoryTextField!.text == nil || categoryTextField!.text == "" { return }
            
            self.filterGroup.title = nameTextField!.text!
            self.navigationItem.title = nameTextField?.text
            self.isNewFilter = false
            
            self.dismiss(animated: true, completion: nil)
            
            completion?(self.filterGroup.title, (categoryTextField?.text)!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            MTLImage.save(self.filterGroup, completion: { (success) in
                self.dismiss(animated: true, completion: nil)
                completion?("", "")
            })
        }
        
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func setupView() {
        actionButton = UIBarButtonItem(title: "•••", style: .done, target: self, action: #selector(FilterGroupViewController.actionButtonPressed(_:)))
        navigationItem.rightBarButtonItem = actionButton
        actionButton.isEnabled = filterGroup.filters.count > 0
    
        navigationItem.title = filterGroup.title
    }
    
    //    MARK: - UITableView
    //    MARK: DataSource
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == filterGroup.filters.count { return 80.0 }
        return 70.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterGroup.filters.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        if indexPath.row == filterGroup.filters.count {
            return tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = filterGroup.filters[indexPath.row].title
        return cell
    }
    
    
    //    MARK: Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        
        actionButton.isEnabled = true
        
        if cell?.reuseIdentifier == "addCell" {
            performSegue(withIdentifier: "addFilter", sender: self)
        }
        else {
            selectedFilter = filterGroup.filters[indexPath.row]
            if selectedFilter is Filter {
                performSegue(withIdentifier: "settings", sender: self)
            }
            else if selectedFilter is FilterGroup {
                performSegue(withIdentifier: "filterGroup", sender: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == filterGroup.filters.count { return false }
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.row == filterGroup.filters.count { return .none }
        return .delete
    }
    
//    MARK: - AddFilterViewController Delegate
    
    var histogramView: UIView?

    func addFilterViewControllerDidSelectFilter(_ sender: AddFilterViewController, filter: MTLObject) {
    
//        Temp test for histogram
//        if histogramView == nil {
//            if filter is Histogram {
//                let histogram = filter as! Histogram
//                if histogram.histogramView != nil {
//                    histogramView = histogram.histogramView
//                    let window = UIApplication.shared.keyWindow!
//                    histogramView!.center = CGPoint(x: view.frame.size.width/2, y: 200)
//                    window.addSubview(histogramView!)
//                }
//            }
//        }
        
        filterGroup += filter
        
        actionButton.isEnabled = true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.deleteRows(at: [indexPath], with: .fade)
            filterGroup.remove(filterGroup.filters[indexPath.row])
            actionButton.isEnabled = filterGroup.filters.count > 0
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if indexPath.row == filterGroup.filters.count { return nil }
        
        let action = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
            self.filterGroup.remove(self.filterGroup.filters[indexPath.row])
            tableView.deleteRows(at: [indexPath], with: .fade)
        })
        
        return [action]
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        filterGroup.move(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == filterGroup.filters.count { return false }
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "settings" {
            settingsViewController = segue.destination as? SettingsViewController
            settingsViewController?.filter = selectedFilter as! Filter
        }
        else if segue.identifier == "addFilter" {
            let navigationController = segue.destination as! UINavigationController
            let addFilterViewController = navigationController.viewControllers.first as! AddFilterViewController
            addFilterViewController.delegate = self
        }
        else if segue.identifier == "filterGroup" {
            let filterGroupViewController = segue.destination as! FilterGroupViewController
            filterGroupViewController.filterGroup = selectedFilter as? FilterGroup
        }
    }

}

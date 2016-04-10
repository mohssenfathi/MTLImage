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
    func filtersViewControllerBackButtonPressed(sender: FiltersViewController)
}

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!

    var settingsViewController: SettingsViewController?
    var selectedFilter: MTLFilter!
    var delegate: FiltersViewControllerDelegate?
    var filterNames = Array(MTLImage.filters.keys).sort()
    var specialFilters: [String]!
    var filterGroup: MTLFilterGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.enabled = false
        
        specialFilters = ["Filter Group"]
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Filters"
    }
    
    func handleTouchAtLocation(location: CGPoint) {
        settingsViewController?.handleTouchAtLocation(location)
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
        if section == 0 { return specialFilters.count }
        return filterNames.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "Multiple Filters" }
        return "Single Filters"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = specialFilters[indexPath.row]
        }
        else {
            cell.textLabel?.text = filterNames[indexPath.row]
        }
        
        return cell
    }
    
    
    //    MARK: Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            performSegueWithIdentifier("filterGroup", sender: self)
        }
        else {
            let title = filterNames[indexPath.row]
            selectedFilter = MTLImage.filters[title]
            delegate?.filtersViewControllerDidSelectFilter(self, filter: selectedFilter)
            performSegueWithIdentifier("settings", sender: self)
        }
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
        }
    }

}

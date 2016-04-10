//
//  AddFilterViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/9/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MTLImage

protocol AddFilterViewControllerDelegate {
    func addFilterViewControllerDidSelectFilter(sender: AddFilterViewController, filter: MTLFilter)
}

class AddFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var delegate: AddFilterViewControllerDelegate?
    var filterNames = Array(MTLImage.filters.keys).sort()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func closeButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //    MARK: - UITableView
    //    MARK: DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = filterNames[indexPath.row]
        return cell
    }
    
    
    //    MARK: Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let title = filterNames[indexPath.row]
        delegate?.addFilterViewControllerDidSelectFilter(self, filter: MTLImage.filters[title]!)
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

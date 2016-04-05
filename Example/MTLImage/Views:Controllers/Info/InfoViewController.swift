//
//  InfoViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/3/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var metadata: [AnyObject]!
    
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
        return metadata.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        let titleLabel = cell.viewWithTag(101) as! UILabel
        let valueLabel = cell.viewWithTag(102) as! UILabel
        
        let dict = metadata[indexPath.row] as! [String : String]
        titleLabel.text = dict["title"]?.capitalizedString
        valueLabel.text = dict["value"]
        
        return cell
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

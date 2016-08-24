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
    var metadata: [[String:Any]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func closeButtonPressed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    
    //    MARK: - UITableView
    //    MARK: DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return metadata.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleLabel = cell.viewWithTag(101) as! UILabel
        let valueLabel = cell.viewWithTag(102) as! UILabel
        
        let dict = metadata[(indexPath as NSIndexPath).row] as! [String : String]
        titleLabel.text = dict["title"]?.capitalized
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

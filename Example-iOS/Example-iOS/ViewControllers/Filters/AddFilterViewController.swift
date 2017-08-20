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
    func addFilterViewControllerDidSelectFilter(_ sender: AddFilterViewController, filter: MTLObject)
}

class AddFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var delegate: AddFilterViewControllerDelegate?
    var filterNames = MTLImage.filters.sorted()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Add Filter"
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
        return filterNames.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = (indexPath.row == 0) ? "New Filter Group" : filterNames[indexPath.row - 1]
        return cell
    }
    
    
    //    MARK: Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            delegate?.addFilterViewControllerDidSelectFilter(self, filter: FilterGroup())
            dismiss(animated: true, completion: nil)
            return
        }
        
        let title = filterNames[indexPath.row - 1]
        delegate?.addFilterViewControllerDidSelectFilter(self, filter: try! MTLImage.filter(title)!)
        dismiss(animated: true, completion: nil)
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

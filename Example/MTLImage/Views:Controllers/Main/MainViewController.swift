//
//  MainViewController.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 3/31/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MTLImage
import Photos

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FiltersViewControllerDelegate, MTLViewDelegate {
    
    @IBOutlet weak var selectPhotoButton: UIBarButtonItem!
    @IBOutlet weak var mtlView: MTLView!
    @IBOutlet weak var filtersBar: UIView!
    @IBOutlet weak var filtersContainer: UIView!
    @IBOutlet weak var filtersContainerHeight: NSLayoutConstraint!
    @IBOutlet var flipButton: UIBarButtonItem!
    @IBOutlet var actionButton: UIBarButtonItem!
    
    var filterGroup = MTLFilterGroup()
    var filtersViewController: FiltersViewController!
    var sourcePicture: MTLPicture!
    var secondSourcePicture: MTLPicture!
    var camera: MTLCamera = MTLCamera()
    var currentInput: MTLInput!
    var canDrag: Bool = false
    var initialDragOffset: CGFloat = 0.0   // removes initial jump on drag
    var metadata: [AnyObject]?
    
    lazy var imagePickerController: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        return imagePicker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "test")!
        
        self.navigationItem.leftBarButtonItems = nil
        
        sourcePicture = MTLPicture(image: image)
//        sourcePicture.setProcessingSize(scrollView.bounds.size * 3.0, respectAspectRatio: true)
        mtlView.delegate = self
        currentInput = sourcePicture
        
        currentInput --> filterGroup --> mtlView
        
        navigationItem.title = "MTLImage"
    }
    
    @IBAction func actionButtonPressed(sender: AnyObject) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let imageAction = UIAlertAction(title: "New Image", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.presentViewController(self.imagePickerController, animated: true) {
                self.filtersViewController.navigationController?.popToRootViewControllerAnimated(false)
            }
        }
        
        let saveAction = UIAlertAction(title: "Save to Library", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion: nil)
            // Do this later
        }
        
        let infoAction = UIAlertAction(title: "Image Information", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion: nil)
            // Do this later
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alert.addAction(imageAction)
        alert.addAction(saveAction)
        alert.addAction(infoAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
        
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
//    MARK: - MTLView Delegate
    
    func mtlViewTouchesBegan(sender: MTLView, touches: Set<UITouch>, event: UIEvent?) {
        let touch: UITouch = touches.first! as UITouch
        let location = touch.locationInView(sender)
        filtersViewController.handleTouchAtLocation(location)
    }
    
    func mtlViewTouchesMoved(sender: MTLView, touches: Set<UITouch>, event: UIEvent?) {
        let touch: UITouch = touches.first! as UITouch
        let location = touch.locationInView(sender)
        filtersViewController.handleTouchAtLocation(location)
        
    }
    
    func mtlViewTouchesEnded(sender: MTLView, touches: Set<UITouch>, event: UIEvent?) {
        
    }
    
    
//    MARK: - Gesture Recognizers
    
    @IBAction func handlePanGesture(sender: AnyObject) {
        let location = sender.locationInView(view)
        
        if sender.state == .Began {
            if CGRectContainsPoint(filtersBar.frame, location) {
                canDrag = true
                initialDragOffset = (location.y - CGRectGetMinY(filtersContainer.frame))
                filtersViewController.navigationController?.navigationBar.barTintColor = UIColor.lightGrayColor()
            }
        }
        else if sender.state == .Ended {
            canDrag = false
            filtersViewController.navigationController?.navigationBar.barTintColor = UIColor .whiteColor()
        }
        else if sender.state == .Changed && canDrag {
            let newHeight = CGRectGetHeight(view.frame) - location.y + initialDragOffset
            if newHeight < (CGRectGetHeight(view.frame) - 150) && newHeight > 125.0 {
                filtersContainerHeight.constant = newHeight
                updateViewConstraints()
            }
        }
        
    }
    
    //    MARK: - UIScrollView Delegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return mtlView
    }
    
//    MARK: - Actions
    
    @IBAction func flipButtonPressed(sender: UIBarButtonItem) {
        camera.flipCamera()
    }
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        
        currentInput.removeAllTargets()
        filterGroup.removeAllTargets()
        
        if sender.selectedSegmentIndex == 0 {
            currentInput = sourcePicture
            navigationItem.rightBarButtonItem = actionButton
        }
        else {
            navigationItem.rightBarButtonItem = nil
            navigationItem.leftBarButtonItem  = flipButton
            currentInput = camera
        }
        
        currentInput --> filterGroup --> mtlView
        currentInput.needsUpdate = true
    }
    
//    MARK: - Image Picker Delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let url = info[UIImagePickerControllerReferenceURL] as! NSURL
        let asset: PHAsset = PHAsset.fetchAssetsWithALAssetURLs([url], options: nil).firstObject as! PHAsset
        MetadataFormatter.sharedFormatter.formatMetadata(asset, completion: { (metadata) in
            self.metadata = metadata
        })
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        sourcePicture.removeAllTargets()
        sourcePicture.image = image
        sourcePicture.setProcessingSize(CGSizeMake(500, 500), respectAspectRatio: true)
        filterGroup.removeAll()
        filterGroup.removeAllTargets()
        
        if filtersViewController.selectedFilter != nil {
            filterGroup.add(filtersViewController.selectedFilter)
        }
        
        sourcePicture --> filterGroup --> mtlView
        
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
//    MARK: - FiltersViewController Delegate
        
    func filtersViewControllerDidSelectFilter(sender: FiltersViewController, filter: MTLObject) {
        filterGroup += filter
    }
    
    func filtersViewControllerBackButtonPressed(sender: FiltersViewController) {
        filterGroup.removeAll()
    }
    
    func filtersViewControllerDidSelectFilterGroup(sender: FiltersViewController, filterGroup: MTLObject) {
        currentInput.removeAllTargets()
        filterGroup.removeAllTargets()
        
        self.filterGroup = filterGroup as! MTLFilterGroup
        
        currentInput --> filterGroup --> mtlView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "filters" {
            let navigationController = segue.destinationViewController as? UINavigationController
            filtersViewController = navigationController?.viewControllers.first as? FiltersViewController
            filtersViewController.delegate = self
            filtersViewController.filterGroup = filterGroup
        }
        if segue.identifier == "info" {
            let navigationController = segue.destinationViewController as? UINavigationController
            let infoViewController = navigationController?.viewControllers.first as? InfoViewController
            infoViewController?.metadata = metadata
        }
    }
    
}

func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

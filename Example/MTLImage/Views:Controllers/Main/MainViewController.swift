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
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mtlView: MTLView!
    @IBOutlet weak var filtersBar: UIView!
    @IBOutlet weak var filtersContainer: UIView!
    @IBOutlet weak var filtersContainerHeight: NSLayoutConstraint!
    @IBOutlet var infoButton: UIBarButtonItem!
    @IBOutlet var libraryButton: UIBarButtonItem!

    var filterGroup = MTLFilterGroup()
    var filtersViewController: FiltersViewController!
    var sourcePicture: MTLPicture!
    var camera: MTLCamera = MTLCamera()
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
        
        self.navigationItem.leftBarButtonItem = nil
        
        
        sourcePicture = MTLPicture(image: image)
        sourcePicture.setProcessingSize(CGSizeMake(500, 500), respectAspectRatio: true)
        mtlView.delegate = self
        
//        sourcePicture > filterGroup
//        filterGroup > mtlView
        
        camera > mtlView
        
        navigationItem.title = "MTLImage"
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
    
    @IBAction func handleDoubleTapGesture(sender: AnyObject) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            scrollView.setZoomScale(2.0, animated: true)
        }
    }
    
    //    MARK: - UIScrollView Delegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return mtlView
    }
    
//    MARK: - Actions
    
    @IBAction func albumButtonPressed(sender: UIBarButtonItem) {
        presentViewController(imagePickerController, animated: true) { 
            self.filtersViewController.navigationController?.popToRootViewControllerAnimated(false)
        }
    }
    
    @IBAction func infoButtonPressed(sender: AnyObject) {
        
    }
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            navigationItem.rightBarButtonItem = libraryButton
        }
        else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
//    MARK: - Image Picker Delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let url = info[UIImagePickerControllerReferenceURL] as! NSURL
        let asset: PHAsset = PHAsset.fetchAssetsWithALAssetURLs([url], options: nil).firstObject as! PHAsset
        MetadataFormatter.sharedFormatter.formatMetadata(asset, completion: { (metadata) in
            self.metadata = metadata
        })
        
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        navigationItem.leftBarButtonItem = infoButton
        
        sourcePicture.image = image
        sourcePicture.setProcessingSize(CGSizeMake(500, 500), respectAspectRatio: true)
        
        if filtersViewController.selectedFilter != nil {
            filtersViewController.selectedFilter.removeAllTargets()
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
//    MARK: - FiltersViewController Delegate
    
    func filtersViewControllerDidSelectFilter(sender: FiltersViewController, filter: MTLFilter) {
        filterGroup += filter
    }
    
    func filtersViewControllerBackButtonPressed(sender: FiltersViewController) {
        filterGroup.removeAll()
    }
    
    func filtersViewControllerDidSelectFilterGroup(sender: FiltersViewController, filterGroup: MTLFilterGroup) {
        sourcePicture.removeAllTargets()
        filterGroup.removeAllTargets()
        
        self.filterGroup = filterGroup
        
        sourcePicture > filterGroup
        filterGroup > mtlView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "filters" {
            let navigationController = segue.destinationViewController as? UINavigationController
            filtersViewController = navigationController?.viewControllers.first as? FiltersViewController
            filtersViewController?.delegate = self
            filtersViewController.filterGroup = filterGroup
        }
        if segue.identifier == "info" {
            let navigationController = segue.destinationViewController as? UINavigationController
            let infoViewController = navigationController?.viewControllers.first as? InfoViewController
            infoViewController?.metadata = metadata
        }
    }
    
}

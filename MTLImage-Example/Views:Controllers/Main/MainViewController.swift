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
    @IBOutlet weak var mtlView: View!
    @IBOutlet weak var filtersBar: UIView!
    @IBOutlet weak var filtersContainer: UIView!
    @IBOutlet weak var filtersContainerHeight: NSLayoutConstraint!
    @IBOutlet var flipButton: UIBarButtonItem!
    @IBOutlet var actionButton: UIBarButtonItem!
    
    var filterGroup = FilterGroup()
    var filtersViewController: FiltersViewController!
    var sourcePicture: Picture!
    var secondSourcePicture: Picture!
    var camera: Camera = Camera()
    var currentInput: Input!
    var canDrag: Bool = false
    var initialDragOffset: CGFloat = 0.0   // removes initial jump on drag
    var metadata: [[String:Any]]?
    
    lazy var imagePickerController: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        return imagePicker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named: "test")!
        
        self.navigationItem.leftBarButtonItems = nil
        
        sourcePicture = Picture(image: image)
        sourcePicture.setProcessingSize(CGSize(width: 400, height: 400), respectAspectRatio: true)
        
        mtlView.delegate = self
        mtlView.contentMode = .scaleAspectFit
        
        currentInput = sourcePicture
        currentInput --> filterGroup --> mtlView
        
        navigationItem.title = "MTLImage"
    }
    
    @IBAction func actionButtonPressed(_ sender: AnyObject) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let imageAction = UIAlertAction(title: "New Image", style: UIAlertActionStyle.default) { (action) in
            self.dismiss(animated: true, completion: nil)
            self.present(self.imagePickerController, animated: true) {
                let _ = self.filtersViewController.navigationController?.popToRootViewController(animated: false)
            }
        }
        
        let saveAction = UIAlertAction(title: "Save to Library", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
            // Do this later
        }
        
        let infoAction = UIAlertAction(title: "Image Information", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
            // Do this later
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(imageAction)
        alert.addAction(saveAction)
        alert.addAction(infoAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
//    MARK: - MTLView Delegate
    
    func mtlViewTouchesBegan(_ sender: View, touches: Set<UITouch>, event: UIEvent?) {
        let touch: UITouch = touches.first! as UITouch
        let location = touch.location(in: sender)
        filtersViewController.handleTouchAtLocation(location)
    }
    
    func mtlViewTouchesMoved(_ sender: View, touches: Set<UITouch>, event: UIEvent?) {
        let touch: UITouch = touches.first! as UITouch
        let location = touch.location(in: sender)
        filtersViewController.handleTouchAtLocation(location)
        
    }
    
    func mtlViewTouchesEnded(_ sender: View, touches: Set<UITouch>, event: UIEvent?) {
        
    }
    
    
//    MARK: - Gesture Recognizers
    
    @IBAction func handlePanGesture(_ sender: AnyObject) {
        let location = sender.location(in: view)
        
        if sender.state == .began {
            if filtersBar.frame.contains(location) {
                canDrag = true
                initialDragOffset = (location.y - filtersContainer.frame.minY)
                filtersViewController.navigationController?.navigationBar.barTintColor = UIColor.lightGray
            }
        }
        else if sender.state == .ended {
            canDrag = false
            filtersViewController.navigationController?.navigationBar.barTintColor = UIColor .white
        }
        else if sender.state == .changed && canDrag {
            let newHeight = view.frame.height - location.y + initialDragOffset
            if newHeight < (view.frame.height - 150) && newHeight > 125.0 {
                filtersContainerHeight.constant = newHeight
                updateViewConstraints()
            }
        }
        
    }
    
    //    MARK: - UIScrollView Delegate
    
    func viewForZoomingInScrollView(_ scrollView: UIScrollView) -> UIView? {
        return mtlView
    }
    
//    MARK: - Actions
    
    @IBAction func flipButtonPressed(_ sender: UIBarButtonItem) {
        camera.flip()
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
                
        let url = info[UIImagePickerControllerReferenceURL] as! URL
        guard let asset: PHAsset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).firstObject else {
            return
        }
        
        MetadataFormatter.sharedFormatter.formatMetadata(asset) { (metadata) in
            self.metadata = metadata
        }
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        sourcePicture.removeAllTargets()
        sourcePicture.image = image
        sourcePicture.setProcessingSize(CGSize(width: 500, height: 500), respectAspectRatio: true)
        filterGroup.removeAll()
        filterGroup.removeAllTargets()
        
        if filtersViewController.selectedFilter != nil {
            filterGroup.add(filtersViewController.selectedFilter)
        }
        
        sourcePicture --> filterGroup --> mtlView
        
        dismiss(animated: true, completion: nil)
    }
    
    
//    MARK: - FiltersViewController Delegate
        
    func filtersViewControllerDidSelectFilter(_ sender: FiltersViewController, filter: MTLObject) {
        filterGroup += filter
    }
    
    func filtersViewControllerBackButtonPressed(_ sender: FiltersViewController) {
        filterGroup.removeAll()
    }
    
    func filtersViewControllerDidSelectFilterGroup(_ sender: FiltersViewController, filterGroup: MTLObject) {
        currentInput.removeAllTargets()
        filterGroup.removeAllTargets()
        
        self.filterGroup = filterGroup as! FilterGroup
        
        currentInput --> filterGroup --> mtlView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "filters" {
            let navigationController = segue.destination as? UINavigationController
            filtersViewController = navigationController?.viewControllers.first as? FiltersViewController
            filtersViewController.delegate = self
            filtersViewController.filterGroup = filterGroup
        }
        if segue.identifier == "info" {
            let navigationController = segue.destination as? UINavigationController
            let infoViewController = navigationController?.viewControllers.first as? InfoViewController
            infoViewController?.metadata = metadata
        }
    }
    
}

func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

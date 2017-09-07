//
//  ViewController.swift
//  Example-macOS
//
//  Created by Mohssen Fathi on 8/30/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import MTLImage_macOS

class ViewController: NSViewController {

    @IBOutlet var renderView: View!
//    let image = Image(image: #imageLiteral(resourceName: "test"))
    let camera = Camera()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        camera.preset = .photo
        camera --> SobelEdgeDetection() --> renderView
    }

}


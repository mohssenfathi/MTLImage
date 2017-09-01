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
    let image = Image(image: #imageLiteral(resourceName: "test"))
    let camera = Camera()
    let dataOutput = DataOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let blur = GaussianBlur()
        blur.sigma = 0.2
        
//        camera --> Sketch() --> blur --> renderView
        camera --> blur --> renderView
        
        dataOutput.newDataAvailable = { data in
            print(CACurrentMediaTime())
        }
        
        camera.newTextureAvailable = { texture in
//            self.dataOutput.process()
        }
    }

}


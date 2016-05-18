//
//  MTLHoughLineDetection.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

public
class MTLHoughLineDetectionFilterGroup: MTLFilterGroup {
    
    let cannyEdgeDetection = MTLCannyEdgeDetectionFilterGroup()
//    let parallelLineTransform =
    let nonMaximumSuppressionFilter = MTLNonMaximumSuppressionThreshodFilter()
    
    override init() {
        super.init()
        
        title = "Hough Line Detection"
        
        add(cannyEdgeDetection)
        add(nonMaximumSuppressionFilter)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

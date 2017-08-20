//
//  CannyEdgeDetectionGroup.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

class CannyEdgeDetection: FilterGroup {
    
    let saturationFilter = Saturation()
    let edgeDetectionFilter = SobelEdgeDetection()
    let blurFilter = GaussianBlur()
    let nonMaximumSuppressionFilter = NonMaximumSuppression()
    let weakPixelInclusion = WeakPixelInclusion()

    override init() {
        super.init()
        title = "Canny Edge Detection"
        
        saturationFilter.saturation = 0.0
        blurFilter.sigma = 0.1
        edgeDetectionFilter.edgeStrength = 0.1
        nonMaximumSuppressionFilter.lowerThreshold = 0.1
        nonMaximumSuppressionFilter.upperThreshold = 0.4
        
        add(saturationFilter)
        add(blurFilter)
        add(edgeDetectionFilter)
        add(nonMaximumSuppressionFilter)
        add(weakPixelInclusion)
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

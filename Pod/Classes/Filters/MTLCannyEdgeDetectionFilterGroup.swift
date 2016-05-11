//
//  MTLCannyEdgeDetectionFilterGroup.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

import UIKit

class MTLCannyEdgeDetectionFilterGroup: MTLFilterGroup {
    
    let saturationFilter = MTLSaturationFilter()
    let edgeDetectionFilter = MTLSobelEdgeDetectionFilter()
    let blurFilter = MTLGaussianBlurFilter()
    let nonMaximumSuppressionFilter = MTLNonMaximumSuppressionFilter()
    let weakPixelInclusion = MTLWeakPixelInclusionFilter()

    override init() {
        super.init()
        title = "Canny Edge Detection"
        
        saturationFilter.saturation = 0.0
        blurFilter.blurRadius = 0.1
        edgeDetectionFilter.edgeStrength = 0.1
        nonMaximumSuppressionFilter.lowerThreshold = 0.1
        nonMaximumSuppressionFilter.upperThreshold = 0.4
        
        add(saturationFilter)
        add(blurFilter)
        add(edgeDetectionFilter)
        add(nonMaximumSuppressionFilter)
        add(weakPixelInclusion)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

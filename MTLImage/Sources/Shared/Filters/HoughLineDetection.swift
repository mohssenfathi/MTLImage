//
//  MTLHoughLineDetection.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/11/16.
//
//

public
class HoughLineDetection: FilterGroup {
    
    let cannyEdgeDetection = CannyEdgeDetection()
//    let parallelLineTransform =
    let nonMaximumSuppressionFilter = NonMaximumSuppressionThreshod()
    
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

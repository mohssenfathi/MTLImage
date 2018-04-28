//
//  MinMax.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 4/21/18.
//

import MetalPerformanceShaders

@available(iOS 11.0, *)
public class MinMax: MPS {

    @objc public var region: CGRect = .zero {
        didSet {
            kernel = MPSImageStatisticsMinAndMax(device: device)
            (kernel as! MPSImageStatisticsMinAndMax).clipRectSource = region.mtlRegion
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: nil)
        commonInit()
    }
    
    override init(functionName: String?) {
        super.init(functionName: nil)
        commonInit()
    }
    
    func commonInit() {
        title = "Area Min Max"
        properties = [Property(key: "region", title: "Region", propertyType: .rect)]
    }
    
    public override func update() {
        super.update()
        if region == .zero, let size = input?.texture?.cgSize {
            region = CGRect(origin: .zero, size: size)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

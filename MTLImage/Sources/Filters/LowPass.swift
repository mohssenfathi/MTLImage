//
//  LowPass.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/13/17.
//

public
class LowPass: FilterGroup {
    
    let buffer = Buffer()
    let blend = Blend()
    
    override init() {
        super.init()
        
        title = "Low Pass"
        blend.blendMode = BlendMode.dissolve.rawValue
        
        add(blend)
        
        blend --> buffer
        blend.add(input: buffer, at: 1)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

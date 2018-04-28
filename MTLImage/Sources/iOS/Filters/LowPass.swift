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
        blend.blendMode = Blend.BlendMode.dissolve.rawValue
        
        add(blend)
        
        blend --> buffer
        blend.inputProvider = { [weak self] index in
            return self?.buffer
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

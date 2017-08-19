//
//  Buffer.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/15/17.
//

public
class Buffer: Filter {
    
    var textureQueue = [MTLTexture]()
    
    public init() {
        super.init(functionName: "EmptyShader")
        title = "Buffer"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func process() {
        
        guard let texture = input?.texture?.copy(device: device) else { return }
        
        textureQueue.insert(texture, at: 0)
        
        if textureQueue.count > bufferLength {
            self.texture = textureQueue.popLast()
        }
    }
    
    // MARK: - Properties
    public var bufferLength: Int = 10 {
        didSet { needsUpdate = true }
    }
}

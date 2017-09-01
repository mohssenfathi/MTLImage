//
//  Copy.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 9/1/17.
//

public
class Copy: Filter {

    public init() {
        super.init(functionName: nil)
        title = "Copy"
        properties = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
    override func encode(to commandBuffer: MTLCommandBuffer) {
        
        guard let inputTexture = input?.texture,
            let texture = texture else {
            return
        }
        
        if let blit = commandBuffer.makeBlitCommandEncoder() {
            blit.copy(
                from: inputTexture,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOriginMake(0, 0, 0),
                sourceSize: inputTexture.size(),
                to: texture,
                destinationSlice: 0,
                destinationLevel: 0,
                destinationOrigin: MTLOriginMake(0, 0, 0)
            )
            blit.endEncoding()
        }
    }
   
    
}

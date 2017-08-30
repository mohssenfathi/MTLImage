//
//  DataOutput.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/28/17.
//

import UIKit

public
class DataOutput: Filter {
    
    public var newDataAvailable: ((_ data: [UInt8]) -> ())?
    
    public init() {
        super.init(functionName: nil)
        title = "Data Output"
        properties = []
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private var dataBuffer: MTLBuffer!
    
    public override func process() {
        
        input?.processIfNeeded()
        if texture == nil { initTexture() }
        
        texture = input?.texture
        
        guard let texture = texture,
            let commandBuffer = context.commandQueue.makeCommandBuffer(),
            let blit = commandBuffer.makeBlitCommandEncoder() else {
                return
        }
        
        if dataBuffer == nil {
            dataBuffer = context.device.makeBuffer(length: texture.width * texture.height * MemoryLayout<UInt8>.size, options: MTLResourceOptions.storageModeShared)
        }
        
        blit.copy(
            from: texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: texture.size(),
            to: dataBuffer,
            destinationOffset: 0,
            destinationBytesPerRow: texture.width * MemoryLayout<UInt8>.size,
            destinationBytesPerImage: 0,
            options: []
        )
        
        blit.endEncoding()
        
        commandBuffer.addCompletedHandler { commandBuffer in
            self.updateBuffer()
        }
        
        commandBuffer.commit()
    }

    
    func updateBuffer() {
        
        guard let texture = texture else { return }
    
        let ptr: UnsafeMutablePointer<UInt8> = self.dataBuffer.contents().assumingMemoryBound(to: UInt8.self)
        let bptr = UnsafeBufferPointer(start: ptr, count: texture.width * texture.height * MemoryLayout<UInt8>.size)
        let data = [UInt8](bptr)

        newDataAvailable?(data)
    }
}

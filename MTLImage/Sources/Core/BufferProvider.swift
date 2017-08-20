//
//  BufferProvider.swift
//  Pods
//
//  Created by Mohssen Fathi on 9/10/16.
//
//

import UIKit

class BufferProvider: NSObject {

    let inflightBuffersCount: Int = 3
    private var uniformsBuffers: [MTLBuffer]
    private var avaliableBufferIndex: Int = 0
    var bufferSize: Int = 0
    
    init(device:MTLDevice, bufferSize: Int) {
        
        uniformsBuffers = [MTLBuffer]()
        self.bufferSize = bufferSize
        
        for _ in 0 ..< inflightBuffersCount {
            if let uniformsBuffer = device.makeBuffer(length: bufferSize, options: []) {
                uniformsBuffers.append(uniformsBuffer)
            }
        }
    }
    
    func nextBuffer(uniforms: UnsafeRawPointer) -> MTLBuffer {
        
        let buffer = uniformsBuffers[avaliableBufferIndex]
        let bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, uniforms, bufferSize)
//        memcpy(bufferPointer, modelViewMatrix.raw(), bufferSize)
//        memcpy(bufferPointer + sizeof(Float)*Matrix4.numberOfElements(), projectionMatrix.raw(), sizeof(Float)*Matrix4.numberOfElements())
        
        avaliableBufferIndex = (avaliableBufferIndex + 1) % inflightBuffersCount
        
        return buffer
    }
    
}

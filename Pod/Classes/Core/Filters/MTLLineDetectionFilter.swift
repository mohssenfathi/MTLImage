//
//  MTLLineDetectionFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/9/16.
//
//

import UIKit

struct MTLLineDetectionUniforms {
    var sensitivity: Float = 0.5;
}

public
class MTLLineDetectionFilter: MTLFilter {
    
    var uniforms = MTLLineDetectionUniforms()
    
    private var accumulatorBuffer: MTLBuffer!
    private var inputSize: CGSize?
    private let sobelEdgeDetectionThreshold = MTLSobelEdgeDetectionThresholdFilter()
    private let thetaCount: Int = 180
    lazy private var accumulator: [UInt8] = {
        return [UInt8](repeating: 0, count: Int(self.inputSize!.width) * self.thetaCount)
    }()
    
    public var sensitivity: Float = 0.5 {
        didSet {
            clamp(&sensitivity, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "lineDetection")
        title = "Line Detection"
        properties = [MTLProperty(key: "sensitivity", title: "Sensitivity")]
        
        sobelEdgeDetectionThreshold.addTarget(self)
        internalInput = sobelEdgeDetectionThreshold
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func update() {
        if self.input == nil { return }
        
        if inputSize == nil {
            inputSize = context.processingSize
        }
        else {
            if accumulatorBuffer != nil {
                let length = Int(inputSize!.width) * thetaCount
                // TODO: Check Data.Deallocator
                let data = Data(bytesNoCopy: accumulatorBuffer.contents(), count: length, deallocator: Data.Deallocator.none)
                data.copyBytes(to: &accumulator, count: data.count)
                
                let m = accumulator.max()
                print(m)
            }
        }
        
        uniforms.sensitivity = sensitivity
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<MTLLineDetectionUniforms>.size, options: .cpuCacheModeWriteCombined)
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        let accumulator = [Float](repeating: 0, count: Int(inputSize!.width) * thetaCount)
        accumulatorBuffer = device.makeBuffer(bytes: accumulator,
                                                length: accumulator.count * MemoryLayout<Float>.size,
                                               options: .cpuCacheModeWriteCombined)
        commandEncoder.setBuffer(accumulatorBuffer, offset: 0, at: 1)
    }
    
    public override func process() {
        super.process()
        sobelEdgeDetectionThreshold.process()
    }
    
    public override var input: MTLInput? {
        get {
            return internalInput
        }
        set {
            if newValue?.identifier != sobelEdgeDetectionThreshold.identifier {
                sobelEdgeDetectionThreshold.input = newValue
                reload()
                update()
            }
        }
    }
    
}

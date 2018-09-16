//
//  ColorRect.swift
//  Tracker
//
//  Created by Mohssen Fathi on 7/27/17.
//  Copyright © 2017 Mohssen Fathi. All rights reserved.
//

struct ColorPositionUniforms {
    var threshold: Float = 0.5
}

public
class ColorPosition: Filter {
    
    var uniforms = ColorPositionUniforms()
    
    public var outputRect: CGRect {

        /* rect: [minX, maxX, minY, maxY] */

        var r = CGRect(
            x: CGFloat(outputRectArray[0]),
            y: CGFloat(outputRectArray[2]),
            width: CGFloat(outputRectArray[1]),
            height: CGFloat(outputRectArray[3])
        )

        r.size.height = r.height - r.origin.y
        r.size.width = r.width - r.origin.x

//        r = average(newRect: r)

        return r
    }
    
    public var normalizedRect: CGRect {
        guard let inputSize = input?.texture?.size().cgSize else {
            return .zero
        }
        
        return outputRect / inputSize
    }
    
    public var color: UIColor = .clear
    public var threshold: Float = 1.0
    public var smoothing = 1
    public var newRectAvailable: ((ColorPosition) -> ())?
    
    public init() {
        super.init(functionName: "colorPosition")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func update() {
        super.update()
        
        if let contents = outputRectBuffer?.contents() {
            let count = 4
            let result = contents.bindMemory(to: UInt32.self, capacity: count)
            for i in 0 ..< count { outputRectArray[i] = Float(result[i]) }
            newRectAvailable?(self)
        }
        
        uniformsBuffer = context.device.makeBuffer(bytes: &uniforms,
                                                   length: MemoryLayout<ColorPositionUniforms>.size,
                                                   options: .cpuCacheModeWriteCombined)
    }
    
    
    public override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        outputRectBuffer = context.device.makeBuffer(bytes: outputRectArray, length: outputRectArray.count * MemoryLayout<Float>.size, options: .storageModeShared)
        
        commandEncoder.setBuffer(outputRectBuffer, offset: 0, index: 1)
    }
    
    
    var outputRectBuffer: MTLBuffer? = nil
    var outputRectArray: [Float] = [100000, -1, 100000, -1]
    
    
    // MARK: - Smoothing
    private var outputRectSum: CGRect = .zero
    private var outputRectHistory = [CGRect]()
    
    private func average(newRect: CGRect) -> CGRect {
        
        outputRectHistory.insert(newRect, at: 0)
        outputRectSum = outputRectSum + newRect
        
        if outputRectHistory.count > smoothing {
            outputRectSum = outputRectSum - (outputRectHistory.popLast() ?? .zero)
        }
        
        return outputRectSum / min(CGFloat(outputRectHistory.count), CGFloat(smoothing))
    }
}


func +(left: CGRect, right: CGRect) -> CGRect {
    return CGRect(
        x: left.origin.x + right.origin.x,
        y: left.origin.y + right.origin.y,
        width: left.size.width + right.size.width,
        height: left.size.height + right.size.height
    )
}

func -(left: CGRect, right: CGRect) -> CGRect {
    return CGRect(
        x: left.origin.x - right.origin.x,
        y: left.origin.y - right.origin.y,
        width: left.size.width - right.size.width,
        height: left.size.height - right.size.height
    )
}


func /(left: CGRect, right: CGFloat) -> CGRect {
    return CGRect(
        x: left.origin.x / right,
        y: left.origin.y / right,
        width: left.size.width / right,
        height: left.size.height / right
    )
}

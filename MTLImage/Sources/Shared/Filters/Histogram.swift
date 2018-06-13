//
//  Histogram.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/24/17.
//

import MetalPerformanceShaders

public
class Histogram: MPS {

    @objc public var numberOfEntries: Int = 256 {
        didSet {
            reloadKernel()
            needsUpdate = true
        }
    }
    
    public var newHistogramAvailable: (((red: [UInt32], green: [UInt32], blue: [UInt32], alpha: [UInt32])) -> ())?
    
    public var red: [UInt32]!
    public var green: [UInt32]!
    public var blue: [UInt32]!
    public var alpha: [UInt32]!
    
    private var histogramValues: [UInt32] = []
    private var histogramBuffer: MTLBuffer!
    
    public init() {
        super.init(functionName: nil)
        commonInit()
    }
    
    override init(functionName: String?) {
        super.init(functionName: nil)
        commonInit()
    }
    
    func reloadKernel() {
        
        red = [UInt32](repeating: 0, count: numberOfEntries)
        green = [UInt32](repeating: 0, count: numberOfEntries)
        blue = [UInt32](repeating: 0, count: numberOfEntries)
        alpha = [UInt32](repeating: 0, count: numberOfEntries)
        
        var info = MPSImageHistogramInfo(
            numberOfHistogramEntries: numberOfEntries,
            histogramForAlpha: true,
            minPixelValue: vector_float4([0, 0, 0, 0]),
            maxPixelValue: vector_float4([1, 1, 1, 1])
        )
        
        kernel = MPSImageHistogram(device: context.device, histogramInfo: &info)
        (kernel as! MPSImageHistogram).zeroHistogram = true
    }
    
    override public func update() {
        super.update()
        
        guard histogramBuffer != nil else { return }

        let pointer = histogramBuffer.contents().assumingMemoryBound(to: UInt32.self)
        let bufferPointer = UnsafeBufferPointer(start: pointer, count: histogramBuffer.length)
        histogramValues = [UInt32](bufferPointer)

        let len = numberOfEntries
        
        red   = [UInt32](histogramValues[len * 0 ..< len * 1])
        green = [UInt32](histogramValues[len * 1 ..< len * 2])
        blue  = [UInt32](histogramValues[len * 2 ..< len * 3])
        alpha = [UInt32](histogramValues[len * 3 ..< len * 4])
        
//        newHistogramAvailable?((red, green, blue, alpha))
    }
    
    override var shouldProcess: Bool {
        return input?.texture != nil
    }
    
    public override func process() {
        texture = input?.texture
        super.process()
    }
    
    override func configureCommandBuffer(_ commandBuffer: MTLCommandBuffer) {
        super.configureCommandBuffer(commandBuffer)
        
        guard let inputTexture = input?.texture else { return }
        
        let bufferLength = (kernel as! MPSImageHistogram).histogramSize(forSourceFormat: inputTexture.pixelFormat)/MemoryLayout<UInt32>.size
        histogramBuffer = device.makeBuffer(length: bufferLength, options: [.storageModeShared])
        
        (kernel as! MPSImageHistogram).encode(
            to: commandBuffer,
            sourceTexture: inputTexture,
            histogram: histogramBuffer,
            histogramOffset: 0
        )
    }
    
    public override func didFinishProcessing(_ filter: Filter) {
        super.didFinishProcessing(filter)
        
        newHistogramAvailable?((red, green, blue, alpha))
    }
    
    func commonInit() {
        title = "Histogram"
        properties = [Property(key: "numberOfEntries", title: "Number of Entries")]
        
        reloadKernel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

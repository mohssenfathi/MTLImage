//
//  MTLHistogramFilter.swift
//  Pods
//
//  Created by Mohammad Fathi on 4/25/16.
//
//

import UIKit

struct HistogramUniforms {
    var dummy: Float = 0.5
}

public
class MTLHistogramFilter: MTLFilter {
    
    var uniforms = HistogramUniforms()

    public var luminance = [Float](repeating: 0, count: 255)
    public var red       = [Float](repeating: 0, count: 255)
    public var green     = [Float](repeating: 0, count: 255)
    public var blue      = [Float](repeating: 0, count: 255)
    
    var luminanceBuffer: MTLBuffer?
    var redBuffer      : MTLBuffer?
    var greenBuffer    : MTLBuffer?
    var blueBuffer     : MTLBuffer?
    
    var dummy: Float = 0.5 {
        didSet {
            clamp(&dummy, low: 0, high: 1)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "histogram")
        title = "Histogram"
        properties = []
        update()
        createHistogramView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        if luminanceBuffer != nil {
            let data = Data(bytesNoCopy: luminanceBuffer!.contents() as! UnsafeMutablePointer<UInt8>, count: 255 * sizeof(Float), deallocator:  .free)
            data.copyBytes(to: luminance as! UnsafeMutablePointer<UInt8>, count: 255 * sizeof(UInt8))
            smooth(&luminance)
            updateHistogramView(luminance)
        }
        
        if redBuffer != nil {
            let data = Data(bytesNoCopy: redBuffer!.contents() as! UnsafeMutablePointer<UInt8>, count: 255 * sizeof(Float), deallocator: .free)
            data.copyBytes(to: red as! UnsafeMutablePointer<UInt8>, count: 255 * sizeof(UInt8))
            smooth(&red)
            updateHistogramView(red)
        }
        
        if greenBuffer != nil {
            let data = Data(bytesNoCopy: greenBuffer!.contents() as! UnsafeMutablePointer<UInt8>, count: 255 * sizeof(Float), deallocator:  .free)
            data.copyBytes(to: green as! UnsafeMutablePointer<UInt8>, count: 255 * sizeof(UInt8))
            smooth(&green)
            updateHistogramView(green)
        }
        
        if blueBuffer != nil {
            let data = Data(bytesNoCopy: blueBuffer!.contents() as! UnsafeMutablePointer<UInt8>, count: 255 * sizeof(Float), deallocator:  .free)
            data.copyBytes(to: blue as! UnsafeMutablePointer<UInt8>, count: 255 * sizeof(UInt8))
            smooth(&blue)
            updateHistogramView(blue)
        }
        
        uniforms.dummy = dummy
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: sizeof(HistogramUniforms), options: .cpuCacheModeWriteCombined)
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        let f = [Float](repeating: 0, count: 255)
        
        luminanceBuffer = device.newBuffer(withBytes: f, length: f.count * sizeofValue(f[0]), options: .cpuCacheModeWriteCombined)
        redBuffer       = device.newBuffer(withBytes: f, length: f.count * sizeofValue(f[0]), options: .cpuCacheModeWriteCombined)
        greenBuffer     = device.newBuffer(withBytes: f, length: f.count * sizeofValue(f[0]), options: .cpuCacheModeWriteCombined)
        blueBuffer      = device.newBuffer(withBytes: f, length: f.count * sizeofValue(f[0]), options: .cpuCacheModeWriteCombined)
        
        commandEncoder.setBuffer(luminanceBuffer, offset: 0, at: 1)
        commandEncoder.setBuffer(redBuffer      , offset: 0, at: 2)
        commandEncoder.setBuffer(greenBuffer    , offset: 0, at: 3)
        commandEncoder.setBuffer(blueBuffer     , offset: 0, at: 4)
    }
    
    public override func process() {
        update()
        super.process()
    }
    
    
    
    
//    MARK: - View Testing
    
    func smooth(_ values: inout [Float]) {
        let averageRange = 10
        var average: Float = 0.0
        for index in 0 ..< values.count {
            if index < averageRange {
                average = average + values[index] / Float(averageRange)
            }
            else if index >= averageRange && index < values.count - 1 {
                average = ((average * Float(averageRange)) - Float(values[index - averageRange]) + Float(values[index + 1])) / Float(averageRange);
                average = max(average, 0)
            }
            
            if values[index] == 0.0 {
                values[index] = average
            }
        }
    }
    
    public var histogramView: UIView!
    var luminanceView: UIView!
    var redView: UIView!
    var greenView: UIView!
    var blueView: UIView!
    
    func createHistogramView() {
        let width : CGFloat = 300.0
        let height: CGFloat = 250.0
        let dx: CGFloat = width/CGFloat(luminance.count)
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        
        luminanceView = UIView(frame: view.bounds)
        redView       = UIView(frame: view.bounds)
        greenView     = UIView(frame: view.bounds)
        blueView      = UIView(frame: view.bounds)
        
        view.addSubview(redView)
        view.addSubview(greenView)
        view.addSubview(blueView)
        view.addSubview(luminanceView)
        
        view.backgroundColor = UIColor.clear()
        
        var bar: UIView!
        for i in 0 ..< luminance.count {
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.75
            bar.backgroundColor = UIColor.white()
            luminanceView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.red()
            redView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.green()
            greenView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.blue()
            blueView.addSubview(bar)
            
        }
        
        histogramView = view
    }
 
    func maximumHistogramValue() -> Float {
        let maxL = luminance.max()
        let maxR = red.max()
        let maxG = green.max()
        let maxB = blue.max()
        
        return max(max(maxL!, max(maxR!, max(maxG!, maxB!))), 1)
    }
    
    func updateHistogramView(_ values: [Float]) {
        
        let maxValue: CGFloat = CGFloat(maximumHistogramValue())
        let maxHeight = histogramView.frame.size.height * 0.8
        var newHeight: CGFloat!
        var index: Int = 0
        
        var view: UIView!
        if      values == luminance { view = luminanceView }
        else if values == red       { view = redView       }
        else if values == green     { view = greenView     }
        else if values == blue      { view = blueView      }
        else                        { return               }
        
        for bar in view.subviews {
            newHeight = CGFloat(values[index]) / maxValue * maxHeight
            bar.frame = CGRect(x: bar.frame.origin.x, y: view.frame.size.height - newHeight, width: bar.frame.size.width, height: newHeight)
            index = index + 1
        }
    }
}

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

    public var luminance = [Float](count: 255, repeatedValue: 0)
    public var red       = [Float](count: 255, repeatedValue: 0)
    public var green     = [Float](count: 255, repeatedValue: 0)
    public var blue      = [Float](count: 255, repeatedValue: 0)
    
    var luminanceBuffer: MTLBuffer?
    var redBuffer      : MTLBuffer?
    var greenBuffer    : MTLBuffer?
    var blueBuffer     : MTLBuffer?
    
    var dummy: Float = 0.5 {
        didSet {
            clamp(&dummy, low: 0, high: 1)
            dirty = true
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
    
    override func update() {
        if self.input == nil { return }
        
        if luminanceBuffer != nil {
            var data = NSData(bytesNoCopy: luminanceBuffer!.contents(), length: 255 * sizeof(Float), freeWhenDone: false)
            data.getBytes(&luminance, length:255 * sizeof(Float))
            smooth(&luminance)
            updateHistogramView(luminance)
        }
        
        if redBuffer != nil {
            var data = NSData(bytesNoCopy: redBuffer!.contents(), length: 255 * sizeof(Float), freeWhenDone: false)
            data.getBytes(&red, length:255 * sizeof(Float))
            smooth(&red)
            updateHistogramView(red)
        }
        
        if greenBuffer != nil {
            var data = NSData(bytesNoCopy: greenBuffer!.contents(), length: 255 * sizeof(Float), freeWhenDone: false)
            data.getBytes(&green, length:255 * sizeof(Float))
            smooth(&green)
            updateHistogramView(green)
        }
        
        if blueBuffer != nil {
            var data = NSData(bytesNoCopy: blueBuffer!.contents(), length: 255 * sizeof(Float), freeWhenDone: false)
            data.getBytes(&blue, length:255 * sizeof(Float))
            smooth(&blue)
            updateHistogramView(blue)
        }
        
        uniforms.dummy = dummy
        uniformsBuffer = device.newBufferWithBytes(&uniforms, length: sizeof(HistogramUniforms), options: .CPUCacheModeDefaultCache)
    }
    
    override func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        let f = [Float](count: 255, repeatedValue: 0)
        
        luminanceBuffer = device.newBufferWithBytes(f, length: f.count * sizeofValue(f[0]), options: .CPUCacheModeDefaultCache)
        redBuffer       = device.newBufferWithBytes(f, length: f.count * sizeofValue(f[0]), options: .CPUCacheModeDefaultCache)
        greenBuffer     = device.newBufferWithBytes(f, length: f.count * sizeofValue(f[0]), options: .CPUCacheModeDefaultCache)
        blueBuffer      = device.newBufferWithBytes(f, length: f.count * sizeofValue(f[0]), options: .CPUCacheModeDefaultCache)
        
        commandEncoder.setBuffer(luminanceBuffer, offset: 0, atIndex: 1)
        commandEncoder.setBuffer(redBuffer      , offset: 0, atIndex: 2)
        commandEncoder.setBuffer(greenBuffer    , offset: 0, atIndex: 3)
        commandEncoder.setBuffer(blueBuffer     , offset: 0, atIndex: 4)
    }
    
    public override func process() {
        update()
        super.process()
    }
    
    
    func smooth(inout values: [Float]) {
        let averageRange = 10
        var average: Float = 0.0
        for index in 0 ..< values.count {
            if index < averageRange {
                average = average + values[index] / Float(averageRange)
            }
            else if index >= averageRange && index < values.count - 1 {
                average = ((average * Float(averageRange)) - values[index - averageRange] + values[index + 1]) / Float(averageRange);
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
        
        view.backgroundColor = UIColor.clearColor()
        
        var bar: UIView!
        for i in 0 ..< luminance.count {
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.75
            bar.backgroundColor = UIColor.whiteColor()
            luminanceView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.redColor()
            redView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.greenColor()
            greenView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.blueColor()
            blueView.addSubview(bar)
            
        }
        
        histogramView = view
    }
 
    func maximumHistogramValue() -> Float {
        let maxL = luminance.maxElement()
        let maxR = red.maxElement()
        let maxG = green.maxElement()
        let maxB = blue.maxElement()
        
        return max(max(maxL!, max(maxR!, max(maxG!, maxB!))), 1)
    }
    
    func updateHistogramView(values: [Float]) {
        
        let maxValue: CGFloat = CGFloat(maximumHistogramValue())
        let maxHeight = histogramView.frame.size.height * 0.8
        var newHeight: CGFloat!
        var index: Int = 0
        
        let averageRange = 10
        var average: CGFloat = 0.0
        
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

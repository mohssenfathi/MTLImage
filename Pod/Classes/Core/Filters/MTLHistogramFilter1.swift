//
//  MTLHistogramFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/18/16.
//
//

import UIKit
import MetalPerformanceShaders

public
class MTLHistogramFilter1: MTLMPSFilter {
    
    var histogramInfo: MPSImageHistogramInfo = MPSImageHistogramInfo(numberOfHistogramEntries: 256, histogramForAlpha: true, minPixelValue: float4(0, 0, 0, 0), maxPixelValue: float4(1, 1, 1, 1))
    var histogramInfoPointer: UnsafePointer<MPSImageHistogramInfo>!
    var histogramBuffer: MTLBuffer!
    var histogram: [UInt8]!
    let length = 256 * MemoryLayout<Float>.size
    
    public init() {
        super.init(functionName: "EmptyShader")
        commonInit()
    }
    
    override init(functionName: String) {
        super.init(functionName: "EmptyShader")
        commonInit()
    }
    
    func commonInit() {
        
        title = "Histogram"
        properties = []
        
        histogramBuffer = context.device.makeBuffer(length: 1000 * 1000 * 256, options: .cpuCacheModeWriteCombined)
        histogramInfoPointer = withUnsafePointer(to: &histogramInfo, { (pointer: UnsafePointer<MPSImageHistogramInfo>) -> UnsafePointer<MPSImageHistogramInfo>! in
            return pointer
        })
        kernel = MPSImageHistogram(device: context.device, histogramInfo: histogramInfoPointer)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func configureCommandBuffer(_ commandBuffer: MTLCommandBuffer) {
        super.configureCommandBuffer(commandBuffer)
        
        guard let inputTexture = input?.texture else { return }
        
        (kernel as! MPSImageHistogram).encode(to: commandBuffer, sourceTexture: inputTexture, histogram: histogramBuffer, histogramOffset: 0)
        
        // TODO: Fix this
        let data = Data(bytes: histogramBuffer.contents(), count: length)
//        data.copyBytes(to: &histogram, count: data.count)

//        histogram = Tools.contents(count: length, data: histogramBuffer.contents())
        
        needsUpdate = true
    }
    
    public override var texture: MTLTexture? {
        get {
            if !enabled {
                return input?.texture
            }
            
            if needsUpdate == true {
                update()
                process()
            }
            
            return input?.texture
        }
    }
    
    
    public var luminance = [Float](repeating: 0.0, count: 256)
    public var red       = [Float](repeating: 0.0, count: 256)
    public var green     = [Float](repeating: 0.0, count: 256)
    public var blue      = [Float](repeating: 0.0, count: 256)
    
    
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
        
        view.backgroundColor = UIColor.clear
        
        var bar: UIView!
        for i in 0 ..< luminance.count {
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.75
            bar.backgroundColor = UIColor.white
            luminanceView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.red
            redView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.green
            greenView.addSubview(bar)
            
            bar = UIView(frame: CGRect(x: dx * CGFloat(i), y: height - 1, width: dx, height: 1))
            bar.alpha = 0.5
            bar.backgroundColor = UIColor.blue
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

//
//  ToneCurve.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/30/16.
//
//

import UIKit

struct ToneCurveUniforms: Uniforms {
    
}

public
class ToneCurve: Filter {
    
    var uniforms = ToneCurveUniforms()
    
    var toneCurveBuffer: MTLBuffer? = nil
    
    public var compositeMin: Float = 0.0 {
        didSet {
            clamp(&redMid, low: 0, high: 1)
            compositePoints = [CGPoint(x: 0.0, y: CGFloat(compositeMin)), compositePoints[1], compositePoints[2]]
            compositeCurve = getPreparedSplineCurve(compositePoints)
            toneCurveBuffer = nil
            needsUpdate = true
        }
    }
    
    public var compositeMid: Float = 0.5 {
        didSet {
            clamp(&redMid, low: 0, high: 1)
            compositePoints = [compositePoints[0], CGPoint(x: 0.5, y: CGFloat(compositeMid)), compositePoints[2]]
            compositeCurve = getPreparedSplineCurve(compositePoints)
            toneCurveBuffer = nil
            needsUpdate = true
        }
    }
    
    public var compositeMax: Float = 1.0 {
        didSet {
            clamp(&redMid, low: 0, high: 1)
            compositePoints = [compositePoints[0], compositePoints[1],  CGPoint(x: 1.0, y: CGFloat(compositeMax))]
            compositeCurve = getPreparedSplineCurve(compositePoints)
            toneCurveBuffer = nil
            needsUpdate = true
        }
    }
    
    public var redMid: Float = 0.5 {
        didSet {
            clamp(&redMid, low: 0, high: 1)
            redPoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: CGFloat(redMid)), CGPoint(x: 1.0, y: 1.0)]
            redCurve = getPreparedSplineCurve(redPoints)
            toneCurveBuffer = nil
            needsUpdate = true
        }
    }
    
    public var greenMid: Float = 0.5 {
        didSet {
            clamp(&greenMid, low: 0, high: 1)
            greenPoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: CGFloat(greenMid)), CGPoint(x: 1.0, y: 1.0)]
            greenCurve = getPreparedSplineCurve(greenPoints)
            toneCurveBuffer = nil
            needsUpdate = true
        }
    }
    
    public var blueMid: Float = 0.5 {
        didSet {
            clamp(&blueMid, low: 0, high: 1)
            bluePoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: CGFloat(blueMid)), CGPoint(x: 1.0, y: 1.0)]
            blueCurve = getPreparedSplineCurve(bluePoints)
            toneCurveBuffer = nil
            needsUpdate = true
        }
    }
    
    private var redCurve: [CGFloat]!
    private var blueCurve: [CGFloat]!
    private var greenCurve: [CGFloat]!
    private var compositeCurve: [CGFloat]!
    
    public var redPoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1.0, y: 1.0)] {
        didSet {
            redCurve = getPreparedSplineCurve(redPoints)
            toneCurveBuffer = nil
            needsUpdate = true
            update()
        }
    }
    
    public var greenPoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1.0, y: 1.0)] {
        didSet {
            greenCurve = getPreparedSplineCurve(greenPoints)
            toneCurveBuffer = nil
            needsUpdate = true
            update()
        }
    }
    
    public var bluePoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1.0, y: 1.0)] {
        didSet {
            blueCurve = getPreparedSplineCurve(bluePoints)
            toneCurveBuffer = nil
            needsUpdate = true
            update()
        }
    }
    
    public var compositePoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1.0, y: 1.0)] {
        didSet {
            compositeCurve = getPreparedSplineCurve(compositePoints)
            toneCurveBuffer = nil
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "toneCurve")
        title = "Tone Curve"
        
        setupToneCurveBuffer()
        
        redCurve = getPreparedSplineCurve(redPoints)
        greenCurve = getPreparedSplineCurve(greenPoints)
        blueCurve = getPreparedSplineCurve(bluePoints)
        compositeCurve = getPreparedSplineCurve(compositePoints)
        
        properties = //[]
                     [Property(key: "compositeMin", title: "Composite Min"),
                      Property(key: "compositeMid", title: "Composite Mid"),
                      Property(key: "compositeMax", title: "Composite Max"),
                      Property(key: "redMid"      , title: "Red"),
                      Property(key: "blueMid"     , title: "Blue"),
                      Property(key: "greenMid"    , title: "Green")]
        
        update()
    }
    
    override func updatePropertyValues() {
        super.updatePropertyValues()
        propertyValues["compositeCurve"] = compositeCurve
        propertyValues["redCurve"] = redCurve
        propertyValues["greenCurve"] = greenCurve
        propertyValues["blueCurve"] = blueCurve
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func reset() {
        redPoints   = [CGPoint]()
        greenPoints = [CGPoint]()
        bluePoints  = [CGPoint]()
        compositePoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1.0, y: 1.0)]
    }
    
    override func update() {
        if self.input == nil { return }

        updateUniforms(uniforms: uniforms)
    }
    
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        if toneCurveBuffer == nil {
            updateToneCurveBuffer()
        }
        commandEncoder.setBuffer(toneCurveBuffer, offset: 0, index: 1)
    }
    
    
//    MARK: - Curves
    
    var toneCurveByteArray: UnsafeMutableRawPointer? = nil
    var toneCurveValuesPointer: UnsafeMutablePointer<Float>!
    
    func setupToneCurveBuffer() {
        
        let alignment: UInt = 0x4000
        let size: UInt = UInt(256 * 3) * UInt(MemoryLayout<Float>.size)
        
        posix_memalign(&toneCurveByteArray, Int(alignment), Int(size))
        
        let pptr = OpaquePointer(toneCurveByteArray)
        toneCurveValuesPointer = UnsafeMutablePointer(pptr)
    }
    
    func updateToneCurveBuffer() {
        
        if toneCurveValuesPointer == nil {
            setupToneCurveBuffer()
        }
        
        if (redCurve.count >= 256 &&
            greenCurve.count >= 256 &&
            blueCurve.count >= 256 &&
            compositeCurve.count >= 256) {
            
            let minimum: Float = 0.0
            let maximum: Float = 255.0
            
            for i in 0 ..< 256 {
                
                let fi = Float(i)
                
                let b: Float =  min(max(fi + Float(blueCurve[i]), minimum), maximum)
                toneCurveValuesPointer?[i * 3 + 2] = min(max(b + Float(compositeCurve[Int(b)]), minimum), maximum)
                
                let g: Float =  min(max(fi + Float(greenCurve[i]), minimum), maximum)
                toneCurveValuesPointer?[i * 3 + 1] = min(max(g + Float(compositeCurve[Int(g)]), minimum), maximum)
                
                let r: Float =  min(max(fi + Float(redCurve[i]), minimum), maximum)
                toneCurveValuesPointer?[i * 3 + 0] = min(max(r + Float(compositeCurve[Int(r)]), minimum), maximum)
            }
        }
        else {
            print("Whaaat?")
        }
        
        if toneCurveByteArray == nil {
            print("ToneCurveByteArray is nil");
        }
        
        toneCurveBuffer = device.makeBuffer(bytesNoCopy: toneCurveByteArray!,
                                           length: 256 * 4 * MemoryLayout<Float>.size,
                                           options: MTLResourceOptions.storageModeShared,
                                           deallocator: nil)
    }
    
    
    func getPreparedSplineCurve(_ points: [CGPoint]) -> [CGFloat]? {
        
        _ = points.sorted {
            return $0.x < $1.x
        }
        
        var convertedPoints = [CGPoint]()
        for point in points {
            convertedPoints.append(CGPoint(x: point.x * 255, y: point.y * 255))
        }
        
        guard var splinePoints = splineCurve(convertedPoints) else {
            return [CGFloat](repeating: 0, count: 256)
        }
        
        let firstSplinePoint = splinePoints[0]
    
        if firstSplinePoint.x > 0 {
            for i in (0 ..< Int(firstSplinePoint.x)).reversed() {
                splinePoints.insert(CGPoint(x: i, y: 0), at: 0)
            }
        }
        
        let lastSplinePoint = splinePoints.last!
        if lastSplinePoint.x < 255 {
            for i in Int(lastSplinePoint.x + 1) ... 255 {
                splinePoints.append(CGPoint(x: i, y: 255))
            }
        }
    
        var preparedSplinePoints = [CGFloat]()
        for i in 0 ..< splinePoints.count {
            let newPoint = splinePoints[i]
            let origPoint = CGPoint(x: newPoint.x, y: newPoint.x)
            
            var distance = sqrt(pow((origPoint.x - newPoint.x), 2.0) + pow((origPoint.y - newPoint.y), 2.0))
            if origPoint.y > newPoint.y {
                distance = -distance;
            }
            
            preparedSplinePoints.append(distance)
        }
        
        
        
        return preparedSplinePoints
    }
    

    func splineCurve(_ points: [CGPoint]) -> [CGPoint]? {
        
        guard let sdA = secondDerivative(points) else {
            return nil
        }
        
        let n = sdA.count
        if n < 1 { return nil }
        
        var sd = [Double](repeating: 0, count: n)
        for i in 0 ..< n {
            sd[i] = Double(sdA[i])
        }
        
        let sortedPoints = points.sorted {
            return $0.x < $1.x
        }
        
        var output = [CGPoint]()
        for i in 0 ..< n - 1 {
            let current = sortedPoints[i]
            let next    = sortedPoints[i + 1]
            
            for x in Int(current.x) ..< Int(next.x) {
                let t: CGFloat = (CGFloat(x) - current.x)/(next.x - current.x)
                let a: CGFloat = 1 - t
                let b: CGFloat = t
                let h: CGFloat = next.x - current.x
                
                let y1 = a * current.y + b * next.y
                let y2 = (h * h / 6) * ((a * a * a - a) * CGFloat(sd[i]) + (b * b * b - b) * CGFloat(sd[i + 1]))
                var y = y1 + y2
                
                clamp(&y, low: 0, high: 255)
                
                output.append(CGPoint(x: CGFloat(x), y: y))
            }
        }
        
        output.append(points.last!)
        
        return output
    }
    
    func secondDerivative(_ points: [CGPoint]) -> [CGFloat]? {
        
        let n = points.count
        if n <= 1 { return nil }
        
        var matrix = [[CGFloat]](repeating: [CGFloat](repeating: 0, count: 3), count: n)
        var result = [CGFloat](repeating: 0, count: n)
        
        matrix[0][0] = 0
        matrix[0][1] = 1
        matrix[0][2] = 0
        
        for i in 1 ..< n - 1 {
            let p1 = points[i - 1]
            let p2 = points[i    ]
            let p3 = points[i + 1]
            
            matrix[i][0] = (p2.x - p1.x)/6
            matrix[i][1] = (p3.x - p1.x)/3
            matrix[i][2] = (p3.x - p2.x)/6
            
            result[i] = (p3.y - p2.y) / (p3.x - p2.x) - (p2.y - p1.y) / (p2.x - p1.x)
        }
        
        result[0] = 0
        result[n - 1] = 0
        
        matrix[n - 1][0] = 0
        matrix[n - 1][1] = 1
        matrix[n - 1][2] = 0
        
        for i in 1 ..< n {
            let k = matrix[i][0] / matrix[i-1][1]
            matrix[i][1] = matrix[i][1] - k * matrix[i-1][2]
            matrix[i][0] = 0;
            result[i] = result[i] - k * result[i-1]
        }
        
        for i in (0 ..< n - 2).reversed()  {
            let k = matrix[i][2] / matrix[i + 1][1]
            matrix[i][1] = matrix[i][1] - k * matrix[i + 1][0]
            matrix[i][2] = 0;
            result[i] = result[i] - k * result[i + 1]
        }
        
        var y2 = [CGFloat](repeating: 0, count: n)
        for i in 0 ..< n {
            y2[i] = result[i] / matrix[i][1]
        }
        
        var output = [CGFloat]()
        for i in 0 ..< n {
            output.append(y2[i])
        }
        
        return output
    }
    

}

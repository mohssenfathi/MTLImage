//
//  MTLFilter.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

func ==(left: MTLFilter, right: MTLFilter) -> Bool {
    return left.identifier == right.identifier
}

public
class MTLFilter: MTLObject, NSCoding {
    
    private var propertyValues = [String : AnyObject]()
    private var internalTargets = [MTLOutput]()
    var internalTexture: MTLTexture?
    var internalInput: MTLInput?
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
    var vertexBuffer: MTLBuffer?
    var texCoordBuffer: MTLBuffer?
    var uniformsBuffer: MTLBuffer?
    var index: Int = 0
    var gcd: Int = 0
    
    public init(functionName: String) {
        super.init()
        self.functionName = functionName
    }
    
    public var enabled: Bool = true
    
    var internalTitle: String!
    public override var title: String {
        get { return internalTitle }
        set { internalTitle = newValue }
    }
    
    private var privateIdentifier: String = NSUUID().UUIDString
    public override var identifier: String! {
        get { return privateIdentifier     }
        set { privateIdentifier = newValue }
    }
    
    var source: MTLInput? {
        get {
            var inp: MTLInput? = input
            while inp != nil {
                
                if let sourcePicture = inp as? MTLPicture {
                    return sourcePicture
                }
                
                #if !os(tvOS)
                    if let camera = inp as? MTLCamera {
                        return camera
                    }
                #endif
                
                if inp is MTLOutput {
                    inp = (inp as? MTLOutput)?.input
                }
            }
            return nil
        }
    }
    
    var outputView: MTLView? {
        get {
            // This only checks first target for now. Do DFS later
            var out: MTLOutput? = targets.first
            while out != nil {
                if let filter = out as? MTLFilter {
                    out = filter.targets.first
                }
                else if let filterGroup = out as? MTLFilterGroup {
                    out = filterGroup.targets.first
                }
                else if let mtlView = out as? MTLView {
                    return mtlView
                }
            }
            return nil
        }
    }
    
    var functionName: String!
    public var properties = [MTLProperty]()
    
    public var originalImage: UIImage? {
        get {
            if let picture = source as? MTLPicture {
                return picture.image
            }
            return nil
        }
    }
    
    public var image: UIImage {
        get {
            if needsUpdate == true {
                process()
            }
            return UIImage.imageWithTexture(texture!)!
        }
    }
    
    func update() {
        
    }
    
    public func reset() {
        for property in properties {
            if property.propertyType == MTLPropertyType.Value {
                self.setValue(0.5, forKey: property.key)
            }
        }
    }
    
    func setupPipeline() {
        kernelFunction = context.library?.newFunctionWithName(functionName)
        if kernelFunction == nil {
            print("Failed to load kernel function")
            return
        }
        
        do {
            pipeline = try context.device.newComputePipelineStateWithFunction(kernelFunction)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    public func process() {
        
        guard let inputTexture = input?.texture else {
            print("input texture nil")
            return
        }
        
        autoreleasepool {
            if internalTexture == nil || internalTexture!.width != inputTexture.width || internalTexture!.height != inputTexture.height {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(inputTexture.pixelFormat, width:inputTexture.width,
                    height: inputTexture.height, mipmapped: false)
                internalTexture = context.device?.newTextureWithDescriptor(textureDescriptor)
            }
            
//            if gcd == 0 {
//                // Find the largest denominator? Using a non-divisor will cut pixels off the end
//                gcd = Tools.gcd(inputTexture.width, b: inputTexture.height)
//            }
            // Next, try different values for x, y
            let threadgroupCounts = MTLSizeMake(8, 8, 1)
            let threadgroups = MTLSizeMake(inputTexture.width / threadgroupCounts.width, inputTexture.height / threadgroupCounts.height, 1)
            
            let commandBuffer = context.commandQueue.commandBuffer()
            commandBuffer.label = "MTLFilter: " + title
            
            let commandEncoder = commandBuffer.computeCommandEncoder()
            commandEncoder.setComputePipelineState(pipeline)
            commandEncoder.setBuffer(uniformsBuffer, offset: 0, atIndex: 0)
            commandEncoder.setTexture(inputTexture, atIndex: 0)
            commandEncoder.setTexture(internalTexture, atIndex: 1)
            self.configureCommandEncoder(commandEncoder)
            commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
            commandEncoder.endEncoding()
            
            commandBuffer.addCompletedHandler({ (commandBuffer) in
                self.needsUpdate = false
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
        }
    }
    
    func configureCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        
    }
    
    
    //    MARK: - MTLInput
    
    public override var texture: MTLTexture? {
        get {
            if !enabled {
                return input?.texture
            }
            
            if needsUpdate == true {
                update()
                process()
            }
            return internalTexture
        }
    }
    
    public override var context: MTLContext {
        get {
            if internalInput != nil {
                return internalInput!.context
            }
            return MTLContext()
        }
    }
    
    public override var device: MTLDevice {
        get {
            return context.device
        }
    }
    
    public override var targets: [MTLOutput] {
        get {
            return internalTargets
        }
    }
    
    public override func addTarget(target: MTLOutput) {
        var t = target
        internalTargets.append(t)
        t.input = self
        if let picture = source as? MTLPicture {
            picture.loadTexture()
        }
    }
    
    public override func removeTarget(target: MTLOutput) {
        var t = target
        
        t.input = nil
        
        var index: Int!
        if let filter = target as? MTLFilter {
            for i in 0 ..< internalTargets.count {
                if let f = internalTargets[i] as? MTLFilter {
                    if f == filter { index = i }
                }
            }
        }
        else if t is MTLView {
            for i in 0 ..< internalTargets.count {
                if internalTargets[i] is MTLView { index = i }
            }
        }
        
        internalTargets.removeAtIndex(index)
        internalTexture = nil
    }
    
    public override func removeAllTargets() {
        for var target in internalTargets {
            target.input = nil
        }
        internalTargets.removeAll()
    }
    
    private var privateNeedsUpdate = true
    public override var needsUpdate: Bool {
        set {
            privateNeedsUpdate = newValue
            if newValue == true {
                for target in targets {
                    if let filter = target as? MTLFilter {
                        filter.needsUpdate = newValue
                    }
                }
            }
        }
        get {
            return privateNeedsUpdate
        }
    }
    
    
    //    MARK: - MTLOutput
    
    public override var input: MTLInput? {
        get {
            return internalInput
        }
        set {
            if newValue != nil {
                internalInput = newValue
                setupPipeline()
                update()
            }
        }
    }
    
    
    func updatePropertyValues() {
        propertyValues.removeAll()
        for property in properties {
            propertyValues[property.key] = valueForKey(property.key)
        }
    }
    
    public override func copy() -> AnyObject {
        
        let filter = try! MTLImage.filter(title.lowercaseString) as! MTLFilter

        filter.functionName = functionName
        filter.title = title
        filter.index = index
        filter.properties = properties
        
        updatePropertyValues()
        filter.propertyValues = propertyValues
        
        for property in properties {
            filter.setValue(propertyValues[property.key], forKey: property.key)
        }
        
        filter.uniformsBuffer = uniformsBuffer
        
        return filter
    }
    
    
    
//    MARK: - NSCoding

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(title, forKey: "title")
        aCoder.encodeObject(functionName, forKey: "functionName")
        aCoder.encodeObject(identifier, forKey: "identifier")
        aCoder.encodeInteger(index, forKey: "index")
        updatePropertyValues()
        aCoder.encodeObject(propertyValues, forKey: "propertyValues")
        aCoder.encodeObject(properties, forKey: "properties")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        
        functionName = aDecoder.decodeObjectForKey("functionName") as! String
        identifier   = aDecoder.decodeObjectForKey("identifier") as! String
        properties   = aDecoder.decodeObjectForKey("properties") as! [MTLProperty]
        propertyValues = aDecoder.decodeObjectForKey("propertyValues") as! [String : AnyObject]
        for property in properties {
            setValue(propertyValues[property.key], forKey: property.key)
        }
        title = aDecoder.decodeObjectForKey("title") as! String
        index = aDecoder.decodeIntegerForKey("index")
    }
}
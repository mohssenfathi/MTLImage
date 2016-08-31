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
    
    var propertyValues = [String : Any]()
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
    
    private var privateIdentifier: String = UUID().uuidString
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
            if property.propertyType == MTLPropertyType.value {
                self.setValue(0.5, forKey: property.key)
            }
        }
    }
    
    func setupPipeline() {
        kernelFunction = context.library?.newFunction(withName: functionName)
        if kernelFunction == nil {
            print("Failed to load kernel function: " + functionName)
            return
        }
        
        do {
            pipeline = try context.device.newComputePipelineState(with: kernelFunction)
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
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(with: inputTexture.pixelFormat, width:inputTexture.width,
                    height: inputTexture.height, mipmapped: false)
                internalTexture = context.device?.newTexture(with: textureDescriptor)
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
            commandEncoder.setBuffer(uniformsBuffer, offset: 0, at: 0)
            commandEncoder.setTexture(inputTexture, at: 0)
            commandEncoder.setTexture(internalTexture, at: 1)
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
    
    func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        
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
    
    public override func addTarget(_ target: MTLOutput) {
        var t = target
        internalTargets.append(t)
        t.input = self
        if let picture = source as? MTLPicture {
            picture.loadTexture()
        }
    }
    
    public override func removeTarget(_ target: MTLOutput) {
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
        
        internalTargets.remove(at: index)
        internalTexture = nil
    }
    
    public override func removeAllTargets() {
        for var target in internalTargets {
            target.input = nil
        }
        internalTargets.removeAll()
    }
    
    
    /* Informs next object in the chain that a change has occurred and 
       that changes need to be propogated through the chain. */
    
    private var privateNeedsUpdate = true
    public override var needsUpdate: Bool {
        set {
            privateNeedsUpdate = newValue
            if newValue == true {
                for target in targets where target is MTLObject {
                    (target as! MTLObject).needsUpdate = newValue
                }
            }
        }
        get {
            return privateNeedsUpdate
        }
    }
    
    
    /**
        Filters the provided input image
     
        - parameter image: The original image to be filtered
        - returns: An image filtered by the parent or the parents sub-filters
     */
    
    public func filter(_ image: UIImage) -> UIImage? {
    
        let sourcePicture = MTLPicture(image: image)
        let filterCopy = self.copy() as! MTLFilter
        sourcePicture > filterCopy
        
        guard let tex = filterCopy.texture else {
            return nil
        }
        
        let image = UIImage.imageWithTexture(tex)
        return image
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
            propertyValues[property.key] = value(forKey: property.key)
        }
    }
    
    
    public override func copy() -> Any {
    
        let filter = try! MTLImage.filter(title.lowercased()) as! MTLFilter

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

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: "title")
        aCoder.encode(functionName, forKey: "functionName")
        aCoder.encode(identifier, forKey: "identifier")
        aCoder.encode(index, forKey: "index")
        updatePropertyValues()
        aCoder.encode(propertyValues, forKey: "propertyValues")
        aCoder.encode(properties, forKey: "properties")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        functionName = aDecoder.decodeObject(forKey: "functionName") as! String
        identifier   = aDecoder.decodeObject(forKey: "identifier") as! String
        properties   = aDecoder.decodeObject(forKey: "properties") as! [MTLProperty]
        propertyValues = aDecoder.decodeObject(forKey: "propertyValues") as! [String : AnyObject]
        for property in properties {
            setValue(propertyValues[property.key], forKey: property.key)
        }
        title = aDecoder.decodeObject(forKey: "title") as! String
        index = aDecoder.decodeInteger(forKey: "index")
    }
}

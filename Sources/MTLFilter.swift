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
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
    var vertexBuffer: MTLBuffer?
    var texCoordBuffer: MTLBuffer?
    
    // MARK: - Uniforms
    var uniformsBuffer: MTLBuffer?
    var bufferProvider: MTLBufferProvider? = nil
    
    func updateUniforms<U: Uniforms>(uniforms: U) {
        
        if bufferProvider == nil {
            bufferProvider = MTLBufferProvider(device: context.device, bufferSize: MemoryLayout<U>.size)
        }
        
        var uni = uniforms
        uniformsBuffer = device.makeBuffer(bytes: &uni, length: MemoryLayout<U>.size, options: MTLResourceOptions.storageModeShared)
        //        uniformsBuffer = bufferProvider?.nextBuffer(uniforms: &uni)
    }
    
    var index: Int = 0
    var gcd: Int = 0
    
    deinit {
        texture = nil
        input = nil
        removeAllTargets()
    }
    
    public init(functionName: String?) {
        super.init()
        
        var name = functionName ?? "EmptyShader"
        if name == "" { name = "EmptyShader" }
        self.functionName = name
    }
    
    var outputView: MTLView? {
        get {
            // This only checks first target for now. Do DFS later
            var out: Output? = targets.first
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
    
    public var image: UIImage? {
        get {
            needsUpdate = true
            process()
            
            return texture?.image()
        }
    }
    
    public func reset() {
        for property in properties {
            if property.propertyType == MTLPropertyType.value {
                self.setValue(0.5, forKey: property.key)
            }
        }
    }
    
    override func reload() {
        
        kernelFunction = context.library?.makeFunction(name: functionName)
        if kernelFunction == nil {
            if functionName != "EmptyShader" {
                print("Failed to load kernel function: " + functionName)
            }
            return
        }
        
        do {
            pipeline = try context.device.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("Failed to create pipeline")
        }
        
    }
    
    public override func process() {
        
        guard let inputTexture = input?.texture else { return }
        
        input?.processIfNeeded()
        
        autoreleasepool {
            
            let w = pipeline.threadExecutionWidth
            let h = pipeline.maxTotalThreadsPerThreadgroup / w
            let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
            let threadgroupsPerGrid = MTLSize(width: (inputTexture.width + w - 1) / w, height: (inputTexture.height + h - 1) / h, depth: 1)
            
            let commandBuffer = context.commandQueue.makeCommandBuffer()
            
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            commandEncoder.setComputePipelineState(pipeline)
            commandEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
            commandEncoder.setTexture(inputTexture, index: 0)
            commandEncoder.setTexture(texture, index: 1)
   
            self.configureCommandEncoder(commandEncoder)
            
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            commandEncoder.endEncoding()
            
            commandBuffer.addCompletedHandler({ (commandBuffer) in
                
                if self.continuousUpdate { return }
                if let input = self.input {
                    if input.continuousUpdate { return }
                }
                self.needsUpdate = false
                
            })
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        
    }
    
    
    /**
     Filters the provided input image
     
     - parameter image: The original image to be filtered
     - returns: An image filtered by the parent or the parents sub-filters
     */
    
    public func filter(_ image: UIImage) -> UIImage? {
        
        let sourcePicture = MTLPicture(image: image)
        let filterCopy = self.copy() as! MTLFilter
        sourcePicture --> filterCopy
        
        filterCopy.needsUpdate = true
        filterCopy.processIfNeeded()
        
        guard let tex = filterCopy.texture else {
            return nil
        }
        
        let image = tex.image()
        
        return image
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
    
    
    var threadgroupCounts = MTLSizeMake(8, 8, 1)
    var currentInputSize: CGSize = CGSize.zero
    func updateThreadgroupCounts(width: Int, height: Int) {
        
        currentInputSize = CGSize(width: width, height: height)
        
        let w = Tools.greatestDivisor(width , below: 22)
        let h = Tools.greatestDivisor(height, below: 22)
        
        // TODO: Setting this to 1 will be slow. Find a way ro resize the input texture to be a factor of 8
        threadgroupCounts.width  = (w == NSNotFound) ? 1 : w
        threadgroupCounts.height = (h == NSNotFound) ? 1 : h
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


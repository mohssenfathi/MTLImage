//
//  MTLContext.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

// Set to true to use compiled shaders
let useMetalib = true

public
class Context: NSObject {
    
    public var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var processingSize: CGSize!
    var processingQueue: DispatchQueue!
    var needsUpdate: Bool = true
    let semaphore = DispatchSemaphore(value: 1)
    
    var source: Input?
    var output: Output?
    
    lazy var library: MTLLibrary? = {
        return loadLibrary()
    }()
    
    deinit {
        source = nil
        output = nil
    }
    
    override init() {
        super.init()
        
        device = MTLCreateSystemDefaultDevice()
        guard MTLImage.isMetalSupported else { return }
        
        self.commandQueue = self.device.makeCommandQueue()
        self.processingQueue = DispatchQueue(label: "MTLImageProcessQueue")
        //            DispatchQueue(label: "MTLImageProcessQueue", attributes: DispatchQueueAttributes.concurrent)
        
        refreshCurrentCommandBuffer()
    }
    
    func loadLibrary() -> MTLLibrary? {

        if useMetalib {
            return MTLLib.sharedLibrary(device: device)
        }
        else {
            if #available(iOS 10.0, *) {
                return try? device.makeDefaultLibrary(bundle: Bundle(for: Camera.self))
            } else {
                // This shouldn't be used in production. If it is, user might need to add an empty shader to parent project
                return device.makeDefaultLibrary()
            }
        }
    }
    
    
    /* Returns the full filter chain not including source and output (only first targets for now)
     TODO: Include filters with multiple targets
     */
    var filterChain: [MTLObject] {
        
        guard let source = source else {
            return []
        }
        
        var chain = [MTLObject]()
        var object = source.targets.first as? MTLObject
        
        while object != nil {
            chain.append(object!)
            object = object?.targets.first as? MTLObject
        }
        
        return chain
    }
    
    var currentCommandBuffer: MTLCommandBuffer!
    func refreshCurrentCommandBuffer() {
        currentCommandBuffer = commandQueue.makeCommandBuffer()
    }
    
}

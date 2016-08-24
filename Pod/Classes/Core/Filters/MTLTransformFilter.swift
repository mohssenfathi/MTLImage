//
//  MTLTransformFilter.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/17/16.
//
//

import UIKit

struct TransformUniforms {
    
}

public
class MTLTransformFilter: MTLFilter {
    
    var transform: CATransform3D = CATransform3DMakeScale(1.5, 1.5, 1.0) { // CATransform3DIdentity {
        didSet {
            needsUpdate = true
            update()
        }
    }
    
    var transformBuffer: MTLBuffer?
    
    var uniforms = TransformUniforms()
    
    public var scale: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
//            let val = CGFloat(scale) * 2.0
//            transform = CATransform3DMakeScale(val, val, 1.0)
            needsUpdate = true
            update()
        }
    }
    
    public var rotation: Float = 0.5 {
        didSet {
            clamp(&scale, low: 0, high: 1)
//            let val = CGFloat(rotation) - 1.0
//            transform = CATransform3DMakeRotation(val, 0.0, 0.0, 1.0)
            needsUpdate = true
            update()
        }
    }
    
    public init() {
        super.init(functionName: "transform")
        title = "Transform"
        properties = [MTLProperty(key: "scale", title: "Scale"),
                      MTLProperty(key: "rotation", title: "Rotation")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniformsBuffer = device.newBuffer(withBytes: &uniforms, length: MemoryLayout<TransformUniforms>.size, options: .cpuCacheModeWriteCombined)
    }
    
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        let f = [transform.m11, transform.m12, transform.m13, transform.m14,
                 transform.m21, transform.m22, transform.m23, transform.m24,
                 transform.m31, transform.m32, transform.m33, transform.m34,
                 transform.m41, transform.m42, transform.m43, transform.m44]
        
        transformBuffer = device.newBuffer(withBytes: f, length: f.count * MemoryLayout<CGFloat>.size, options: .cpuCacheModeWriteCombined)
        commandEncoder.setBuffer(transformBuffer, offset: 0, at: 1)
    }
    
//    func updateOrthoMatrix {
//        GLfloat r_l = right - left;
//        GLfloat t_b = top - bottom;
//        GLfloat f_n = far - near;
//        GLfloat tx = - (right + left) / (right - left);
//        GLfloat ty = - (top + bottom) / (top - bottom);
//        GLfloat tz = - (far + near) / (far - near);
//        
//        float scale = 2.0f;
//        if (_anchorTopLeft)
//        {
//            scale = 4.0f;
//            tx=-1.0f;
//            ty=-1.0f;
//        }
//        
//        matrix[0] = scale / r_l;
//        matrix[1] = 0.0f;
//        matrix[2] = 0.0f;
//        matrix[3] = tx;
//        
//        matrix[4] = 0.0f;
//        matrix[5] = scale / t_b;
//        matrix[6] = 0.0f;
//        matrix[7] = ty;
//        
//        matrix[8] = 0.0f;
//        matrix[9] = 0.0f;
//        matrix[10] = scale / f_n;
//        matrix[11] = tz;
//        
//        matrix[12] = 0.0f;
//        matrix[13] = 0.0f;
//        matrix[14] = 0.0f;
//        matrix[15] = 1.0f;
//    }
  
}

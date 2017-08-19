//
//  Transform.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/17/16.
//
//

import UIKit

struct TransformUniforms: Uniforms {
    
}

public
class Transform: Filter {

    var transform: CGAffineTransform = CGAffineTransform.identity { // CGAffineTransform(rotationAngle: CGFloat.pi/4) {
        didSet {
            needsUpdate = true
        }
    }
    
//    var transform: CATransform3D = CATransform3DMakeScale(1.5, 1.5, 1.0) { // CATransform3DIdentity {
//        didSet {
//            needsUpdate = true
//        }
//    }
    
    var transformBuffer: MTLBuffer?
    
    var uniforms = TransformUniforms()
    
    public var scale: Float = 0.0 {
        didSet {
            clamp(&scale, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public var angle: Float = 0.5 {
        didSet {
            clamp(&angle, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "transform")
        title = "Transform"
        properties = [Property(key: "scale", title: "Scale"),
                      Property(key: "angle", title: "Rotation")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        updateUniforms(uniforms: uniforms)
    }
    
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        let s = 1.0 / (1.0 + CGFloat(scale * 10.0))
        let a = CGFloat((angle - 0.5) * 360.0) * CGFloat.pi / 180.0
        
        transform = CGAffineTransform.identity
        transform = transform.rotated(by: a)
        transform = transform.scaledBy(x: s, y: s)
        
        let f: [Float] = [Float(transform.a), Float(transform.b), Float(transform.c),
                          Float(transform.d), Float(transform.tx), Float(transform.ty)]
        
        print(atan2(transform.b, transform.a)) //"\(transform.a)   \(transform.b)")
        
        transformBuffer = device.makeBuffer(bytes: f, length: f.count * MemoryLayout<Float>.size, options: .cpuCacheModeWriteCombined)
        commandEncoder.setBuffer(transformBuffer, offset: 0, index: 1)
        
//        let f = [transform.m11, transform.m12, transform.m13, transform.m14,
//                 transform.m21, transform.m22, transform.m23, transform.m24,
//                 transform.m31, transform.m32, transform.m33, transform.m34,
//                 transform.m41, transform.m42, transform.m43, transform.m44]
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

//
//  ARCamera.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 2/15/18.
//

import UIKit
import ARKit

@available(iOS 11.0, *)
public class ARCamera: CameraBase, Input {
    
    public var arMode: ARMode = .worldTracking
    
    public let arSession = ARSession()
    let sessionDelegate = ARCameraSessionDelegate()
    
    public override init() {
        super.init()
        
        // Disable default camera
        session.stopRunning()
        
        arSession.delegate = sessionDelegate
        sessionDelegate.newFrameAvailable = { frame in
            
            for target in self.targets {
                if var t = target as? AROutput { t.arFrame = frame }
            }
        }
    }
    
    public override func startRunning() {
        arSession.run(arMode.configuration, options: [])
    }
    
    public override func stopRunning() {
        arSession.pause()
    }

    
    // MARK: - Mode
    public enum ARMode {
        
        case worldTracking
        case face
        
        var configuration: ARConfiguration {
            switch self {
            case .worldTracking: return ARWorldTrackingConfiguration()
            case .face:          return ARFaceTrackingConfiguration()
            }
        }
    }
    
    
    // MARK: - Input
    public var texture: MTLTexture?
    public var context: Context = Context()
    public var commandBuffer: MTLCommandBuffer? { return context.commandQueue?.makeCommandBuffer() }
    public var device: MTLDevice { return context.device }
    public var targets: [Output] = []
    public var title: String = "AR Camera"
    public var id: String = UUID().uuidString
    public var needsUpdate: Bool = false
    public var continuousUpdate: Bool = true
    
    
    public func addTarget(_ target: Output) {
        var t = target
        targets.append(t)
        t.input = self
        startRunning()
    }
    
    public func removeTarget(_ target: Output) {
        var t = target
        t.input = nil
    }
    
    public func removeAllTargets() {
        targets.removeAll()
        stopRunning()
    }
    
}


@available(iOS 11.0, *)
class ARCameraSessionDelegate: NSObject, ARSessionDelegate {
 
    var newFrameAvailable: ((ARFrame) -> ())?
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        newFrameAvailable?(frame)
    }

}



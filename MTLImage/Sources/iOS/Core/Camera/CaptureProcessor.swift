//
//  PhotoProcessor.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/5/18.
//

import Foundation
import Photos
import AVFoundation
import MobileCoreServices

@available(iOS 10.0, *)
class CaptureProcessor: NSObject {
    
    typealias CaptureHandler = ((_ captureProcessor: CaptureProcessor, _ photo: Data?, _ depthMap: CVPixelBuffer?, _ metadata: PhotoMetadata?, _ error: Error?) -> ())
    typealias LivePhotoHandler = ((_ captureProcessor: CaptureProcessor, _ asset: PHAsset?, _ error: Error?) -> ())
    
    let identifier: String
    let captureHandler: CaptureHandler
    let livePhotoHandler: LivePhotoHandler?
    let settings: AVCapturePhotoSettings
    
    init(settings: AVCapturePhotoSettings, livePhotoHandler: LivePhotoHandler?, captureHandler: @escaping CaptureHandler) {
        
        self.identifier = UUID().uuidString
        self.settings = settings
        self.livePhotoHandler = livePhotoHandler
        self.captureHandler = captureHandler
    }
    
    func cleanup() {
        if let livePhotoCompanionMoviePath = livePhotoCompanionMovieURL?.path {
            if FileManager.default.fileExists(atPath: livePhotoCompanionMoviePath) {
                do {
                    try FileManager.default.removeItem(atPath: livePhotoCompanionMoviePath)
                } catch {
                    print("Could not remove file at url: \(livePhotoCompanionMoviePath)")
                }
            }
        }
    }
    
    private var photoData: Data?
    private var depthMap: CVPixelBuffer?
    private var livePhotoCompanionMovieURL: URL?
}

@available(iOS 10.0, *)
extension CaptureProcessor: AVCapturePhotoCaptureDelegate {
    
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        photoData = photo.fileDataRepresentation()
        depthMap = photo.depthData?.depthDataMap
        
        process(photo: photo) { [weak self] imageData in
            guard let weakSelf = self else { return }
            weakSelf.captureHandler(weakSelf, weakSelf.photoData, weakSelf.depthMap, try? PhotoMetadata(metadata: photo.metadata), error)
        }
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard let sampleBuffer = photoSampleBuffer,
            let jpeg = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                captureHandler(self, nil, nil, nil, error)
                return
        }
        
        photoData = jpeg
        captureHandler(self, jpeg, nil, nil, error)
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
            cleanup()
            return
        }
        
        guard let photoData = photoData else {
            print("No photo data resource")
            cleanup()
            return
        }
        
        var identifier: String?
        
        PHPhotoLibrary.shared().performChanges({
            
            let options = PHAssetResourceCreationOptions()
            let creationRequest = PHAssetCreationRequest.forAsset()
            if #available(iOS 11.0, *) {
                options.uniformTypeIdentifier = self.settings.processedFileType.map { $0.rawValue }
            }
            creationRequest.addResource(with: .photo, data: photoData, options: options)
            
            identifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
            
            if let livePhotoCompanionMovieURL = self.livePhotoCompanionMovieURL {
                let livePhotoCompanionMovieFileResourceOptions = PHAssetResourceCreationOptions()
                livePhotoCompanionMovieFileResourceOptions.shouldMoveFile = true
                creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoCompanionMovieURL, options: livePhotoCompanionMovieFileResourceOptions)
            }
            
        }, completionHandler: { success, error in
            
            // Get the newly created asset
            guard let identifier = identifier,
                let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
                    self.livePhotoHandler?(self, nil, error)
                    self.cleanup()
                    return
            }
            
            self.livePhotoHandler?(self, asset, error)
            self.cleanup()
        })
        
    }
    
    
    /// Live Photo
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        livePhotoCompanionMovieURL = outputFileURL
    }
    
    
    /// RAW
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
    }

}


extension CaptureProcessor {

//    @available(iOS 11.0, *)
//    func process(photo: AVCapturePhoto, completion: ((Data?) -> ())) {
//
//        guard let fallbackImage = photo.fileDataRepresentation() else {
//            completion(nil)
//            return
//        }
//
//        guard let device = Context.device else {
//            completion(fallbackImage)
//            return
//        }
//
//        guard let cgImage = photo.cgImageRepresentation()?.takeRetainedValue() else {
//            completion(fallbackImage)
//            return
//        }
//
//        let ciImage = CIImage(cgImage: cgImage)
//        let colorSpace = ciImage.colorSpace! // Don't force unwrap
//        let outputURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("mtlimage_capture_processor")
//
//        let context = CIContext(mtlDevice: device)
//
//        var options: [AnyHashable : Any] = [:]
//        if let depthData = photo.depthData {
//            options[kCIImageRepresentationAVDepthData] = depthData
//        }
//
//        try? context.writeJPEGRepresentation(of: ciImage, to: outputURL, colorSpace: colorSpace, options: options)
//
//        let data = try? Data(contentsOf: outputURL)
//
//        let image = UIImage(data: data!)
//
//        completion(data)
//    }
    
    @available(iOS 11.0, *)
    func process(photo: AVCapturePhoto, completion: @escaping ((Data?) -> ())) {

        if let depthData = photo.depthData {
            
            let depthProcessor = DepthProcessor()
            let data = photo.fileDataRepresentation()!
            let image = UIImage(data: data)!
            depthProcessor.filter(image: image, depthMap: depthData.depthDataMap) { texture in
                let im = UIImage(texture: texture!)
                let dat = UIImageJPEGRepresentation(im, 1.0)
                completion(dat)
            }
        }
        return
        
        guard let fallbackImage = photo.fileDataRepresentation() else {
            completion(nil)
            return
        }
        
        guard let cgImage = photo.cgImageRepresentation()?.takeRetainedValue() else {
            completion(fallbackImage)
            return
        }

        let outputURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("mtlimage_capture_processor.jpeg")

        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, kUTTypeJPEG, 1, nil) else {
            completion(fallbackImage)
            return
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        if let depthData = photo.depthData {
            
            var auxDataType: NSString?
            if let auxData = depthData.dictionaryRepresentation(forAuxiliaryDataType: &auxDataType), let type = auxDataType {
                CGImageDestinationAddAuxiliaryDataInfo(destination, type, auxData as CFDictionary)
            }
        }

        guard CGImageDestinationFinalize(destination) == true else {
            completion(fallbackImage)
            return
        }

        let data = try? Data(contentsOf: outputURL)
        
        completion(data)

    }
    
}
